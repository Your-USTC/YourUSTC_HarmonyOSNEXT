import { LengthMetrics } from '@ohos.arkui.node'
import { fileIo, storageStatistics } from '@kit.CoreFileKit'
import { application, common, contextConstant } from '@kit.AbilityKit'
import { formatBytes } from '../utils/tools';
import { WantAbility } from '../utils/WantAbility';
import UnifiedPreferences from '../utils/UnifyPreference';
import BackgroundImage from  '../utils/BgImageManager';

@Builder
export function CleanStorageBuilder(name: string, param?: number) {
  CleanStorage();
}

@Entry
@Component
struct CleanStorage {

  @State appSize: number = 0;    // 应用占用
  @State dataSize: number = 0;   // 数据（不含缓存）
  @State cacheSize: number = 0;  // 缓存
  @State deviceSize: number = 0; // 设备总容量
  @State freeSize: number = 0;   // 空闲空间（新增）
  @State otherSize: number = 0;  // 系统和其他App
  @State percentage: string = '计算中…'; // 占用百分比
  context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private async clearCache() {
    this.percentage = '正在清理…';
    let moduleContext: common.Context;
    moduleContext = await application.createModuleContext(this.context, 'entry');
    // 缓存路径/data/storage/el2/base/cache
    // 缓存路径/data/storage/el2/base/cache/web
    // 缓存路径/data/storage/el2/base/haps/entry/cache
    let paths: Array<string> = [moduleContext.cacheDir, moduleContext.cacheDir + '/web', this.context.cacheDir];
    // 缓存路径/data/storage/el1/base/cache
    moduleContext.area = contextConstant.AreaMode.EL1;
    paths.push(moduleContext.cacheDir);
    // 缓存路径/data/storage/el1/base/haps/entry/cache
    this.context.area = contextConstant.AreaMode.EL1;
    paths.push(this.context.cacheDir);
    this.context.area = contextConstant.AreaMode.EL2;

    // 遍历paths数组，彻底删除每个文件夹下的缓存数据
    for (const path of paths) {
      // 等待读取目录完成再处理下一个路径
      const filenames = await fileIo.listFile(path);
      for (const filename of filenames) {
        const dirPath = `${path}/${filename}`;
        // 跳过指定目录
        if (dirPath === '/data/storage/el2/base/cache/web' || dirPath === '/data/storage/el2/base/cache/web/Cookies')
          continue;

        let isDirectory = false;
        try {
          isDirectory = fileIo.statSync(dirPath).isDirectory();
        } catch (err) {
          console.error(`stat path failed: ${dirPath}, error: ${err.message}`);
          // 读取失败直接跳过，不尝试删除
          continue;
        }

        try {
          if (isDirectory)
            fileIo.rmdirSync(dirPath);
          else
            fileIo.unlinkSync(dirPath);
        } catch (delErr) {
          console.error(`remove failed: ${dirPath}, error: ${delErr.message}`);
        }
      }
    }
    // 全部路径循环完毕再执行大小计算
    this.getStorageSize();
  }

  private async getStorageSize() {
    try {
      const stat = await Promise.all([
        storageStatistics.getCurrentBundleStats(),
        storageStatistics.getTotalSize(),
        storageStatistics.getFreeSize()
      ]);
      this.appSize = stat[0].appSize;
      this.cacheSize = stat[0].cacheSize;
      this.dataSize = stat[0].dataSize - this.cacheSize;
      this.deviceSize = stat[1];
      this.freeSize = stat[2];

      const usedTotal = this.appSize + this.dataSize + this.cacheSize;
      this.otherSize = this.deviceSize - usedTotal - this.freeSize;
      const percentNum = usedTotal / this.deviceSize * 100;
      if (percentNum < 0.01)
        this.percentage = '< 0.01%';
      else
        this.percentage = `${percentNum.toFixed(2)}%`;
    } catch(err) {
      this.percentage = `计算占用空间时发生错误：${err}`;
    }
  }

  @State delBackgroundDisabled: boolean = BackgroundImage.imgPath === '';
  @State delAvatarDisabled: boolean = BackgroundImage.avatarPath === '';
  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text() {
              Span(this.percentage)
                .fontSize(30)
                .fontWeight(FontWeight.Bolder)
              Span(`  ${formatBytes(this.appSize + this.dataSize + this.cacheSize, 2, false)} / ${formatBytes(this.deviceSize)}`)
                .fontSize(13)
            }

            DataPanel({
              values: [this.appSize, this.dataSize, this.cacheSize, this.otherSize],
              max: this.deviceSize,
              type: DataPanelType.Line
            })
              .width('100%')
              .height(40)

            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(12), cross: LengthMetrics.vp(6) } }) {
              ComponentLabel({ cmpColor: '#F7CE00', cmpSize: this.appSize, category: '应用' })
              ComponentLabel({ cmpColor: '#F76223', cmpSize: this.dataSize, category: '数据' })
              ComponentLabel({ cmpColor: '#F772AC', cmpSize: this.cacheSize, category: '缓存' })
              ComponentLabel({ cmpColor: '#A575EB', cmpSize: this.otherSize, category: '系统和其他 App' })
              ComponentLabel({ cmpColor: '#22c3c7c0', cmpSize: this.freeSize, category: '可用' })
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(23)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)

          Column() {
            Row({ space: 5 }) {
              Image($r('app.media.clean'))
                .height(22)
                .width(22)
                .margin({ right: 12, left: 6 })
              Text($r('app.string.clean_cache'))
                .layoutWeight(1)
                .fontSize(16)
            }
            .width('100%')
            .onClick(() => this.clearCache())
            .height(42)

            Divider();

            Row({ space: 5 }) {
              Image($r('app.media.remove_cookie'))
                .height(22)
                .width(22)
                .margin({ right: 12, left: 6 })
              Text($r('app.string.wipe_cookie'))
                .layoutWeight(1)
                .fontSize(16)
            }
            .width('100%')
            .height(42)
            .onClick(() => {
              try {
                // this.webviewController.removeCache(true);
                fileIo.rmdirSync('/data/storage/el2/base/cache/web/Cookies');
                // webview.WebCookieManager.clearAllCookiesSync();
                // webview.WebCookieManager.clearSessionCookieSync();
                this.getStorageSize();
              } catch (error) {
                console.error(`rmdirSync ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            })

            Divider();

            Row({ space: 5 }) {
              Image($r('app.media.picture_damage'))
                .height(22)
                .width(22)
                .margin({ right: 12, left: 6 })
              Text($r('app.string.delete_background_image'))
                .layoutWeight(1)
                .fontSize(16)
            }
            .width('100%')
            .height(42)
            .opacity(this.delBackgroundDisabled ? 0.4 : 1)
            .onClick(() => {
              if (!this.delBackgroundDisabled) {
                this.delBackgroundDisabled = true;
                BackgroundImage.deleteBackgroundImage();
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.clear_success') });
                this.getStorageSize();
              }
            })

            Divider();

            Row({ space: 5 }) {
              Image($r('app.media.picture_damage'))
                .height(22)
                .width(22)
                .margin({ right: 12, left: 6 })
              Text($r('app.string.delete_avatar_image'))
                .layoutWeight(1)
                .fontSize(16)
            }
            .width('100%')
            .height(42)
            .opacity(this.delAvatarDisabled ? 0.4 : 1)
            .onClick(() => {
              if (!this.delAvatarDisabled) {
                this.delAvatarDisabled = true;
                BackgroundImage.deleteAvatar();
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.clear_success') });
                this.getStorageSize();
              }
            })

            Divider();

            Row({ space: 5 }) {
              Image($r('app.media.exclamationmark_circle'))
                .height(22)
                .width(22)
                .margin({ right: 12, left: 6 })
              Text($r('app.string.manual_fault'))
                .layoutWeight(1)
                .fontSize(16)
                .fontColor($r('app.color.red'))
            }
            .width('100%')
            .height(42)
            .onClick(() => {
              UnifiedPreferences.putSync('RecoveryMode', true);
              WantAbility.restart(this.context);
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16})
          .borderRadius(23)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
        }
        .padding(8)
        .width('100$')
      }
      .padding(9)
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .onReady(() => this.getStorageSize())
    .title($r('app.string.storage_stat'), {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#0000')
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
  }
}


@Component
struct ComponentLabel {
  @Prop cmpColor: string;
  @Prop cmpSize: number;
  @Prop category: string = '';
  build() {
    Row({ space: 4 }) {
      Circle()
        .fill(this.cmpColor)
        .height(12)
        .width(12)
      Text(`${this.category} ${formatBytes(this.cmpSize, 2, false)}`)
        .fontSize(12)
    }
  }
}