
import { LinkAddress, LinkSet, MultiLink } from '../constants/Links';
import { LINK } from '../constants/Links';
import * as FunctionOrder from '../utils/FunctionOrder';
import * as tools from '../utils/tools';
import BackgroundImage from '../utils/BgImageManager';
import CustomClickDialog from './CustomClickDialog';
import { Popup } from '@kit.ArkUI';
import MessageDialog from './MessageDialog';
import { resetWebName } from './MultiPageMenu';
import { linkPickerDialog, pushRedirect } from '../utils/PageRouter';

@Component
export struct GridComponent {
  @Prop gridData: LinkSet = { title: '', set: [] };
  @State gridIndex: number = 0;
  gridDialog: CustomDialogController | undefined;
  @Link copyMostUsedFunc: MultiLink[];

  pageInfo: NavPathStack = new NavPathStack();
  build() {
    Column() {
      Text(this.gridData.title) // 功能界面各组的标题
        .fontSize('20fp')
        .height('30vp')
        .fontWeight(FontWeight.Bold)
        .margin({ top: '10vp' })
        .padding({ left: '15vp' })
        .width('100%')

      Grid() {
        ForEach(this.gridData.set, (item: MultiLink, index: number) => { // index: 当前GridComponent的索引
          GridItem() {
            Column() {
              Image(FunctionOrder.gIndex_to_pic(this.gridIndex, index))
                .objectFit(ImageFit.Contain)
                .width('40vp')
                .height('40vp')
                .draggable(false)
              Text(item.title)
                .fontSize('12fp')
                .textAlign(TextAlign.Center)
                .margin({ top: '4vp' })
                .height('17vp')
            }
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .focusable(false)
          .height('64vp')
          .gesture(LongPressGesture()
            .onAction((event: GestureEvent | undefined) => {
              if (!event)
                return;

              this.gridDialog = new CustomDialogController({
                builder: CustomClickDialog({ gridIndex: this.gridIndex, index: index, copyMostUsedFunc: this.copyMostUsedFunc }),
                autoCancel: false,
                gridCount: 4
              });
              this.gridDialog.open();
            })
          )
          .onClick(() => {
            const paramData = LINK[this.gridIndex].set[index];
            // const paramData = LINK.get(this.gridIndex.toString() + '.' + index.toString());
            if (paramData) { // 已设置对应网址
              this.openMultiLink(paramData, index);
              this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
            } else { // 未设置对应网址
              this.getUIContext().getPromptAction().showToast({
                message: $r('app.string.under_construction'),
                duration: 500
              });
            }
          })
        },(item:string,index:number)=>index+JSON.stringify(item))
      }
      .padding(12)
      .rowsGap('8vp')
      .scrollBar(BarState.Off)
      .columnsTemplate('repeat(auto-fit, 70)');
    }
    .margin({ bottom: '16vp' })
    .borderRadius(20)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
  }

  openMultiLink(linkDetail: MultiLink, linkIndex: number) {
    // 记录并刷新点击次数
    // webName.push(LINK.get(preName)?.title ?? 'blank');
    resetWebName(linkDetail.title);
    FunctionOrder.recordClick(this.gridIndex, linkIndex);
    FunctionOrder.refreshFunc();

    // 打开对应页面，如果是多页面就弹出对话框
    if (linkDetail.url.length === 1) {
      pushRedirect(this.pageInfo, linkDetail.url[0], linkDetail.title as string)
    } else if (linkDetail.url.length > 1) { // 防止为空
      this.gridDialog = new CustomDialogController({
        builder: linkPickerDialog({
          gridIndex: this.gridIndex,
          index: linkIndex,
          pageInfo: this.pageInfo
        }),
        autoCancel: true,
        gridCount: 3
      });
      this.gridDialog.open();
    }
  }
}

@Component
export struct MostRecentComponent {
  @Prop gridData: MultiLink[];
  gridDialog: CustomDialogController | undefined;
  @Link copyMostUsedFunc: MultiLink[];

  pageInfo: NavPathStack = new NavPathStack();
  build() {
    Column() {
      // 最常访问
      Row({ space: 6 }) {
        Text($r('app.string.ZuiChangFangWen'))
          .fontSize('20fp')
          .height('30vp')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          Image($r('app.media.more'))
            .height(20)
            .width(20)
        }
        .height(36)
        .width(36)
        .onClick(() => {
          this.getUIContext().showTextPickerDialog({
            selected: FunctionOrder.maxRecord - 1,
            range: (tools.getContArray([[1, 28]], true) as string[]).map(count => `至多显示 ${count} 个`), // 允许用户选择的最大显示数量上限
            defaultPickerItemHeight: 36,
            canLoop: false,
            onAccept: (value: TextPickerResult) => {
              FunctionOrder.setMaxRecord(value.index as number + 1);
              this.getUIContext().getPromptAction().showToast({ message: `已更改为 ${value.value}` });
              FunctionOrder.refreshFunc(); // 刷新点击次数显示
              this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
            }
          })
        })

        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          Image($r('app.media.sort'))
            .height(20)
            .width(20)
        }
        .height(36)
        .width(36)
        .bindPopup(this.showPopup, {
          builder: this.frequencyPopup(),
          placement: Placement.Bottom,
          width: 300,
          onStateChange: (status) => {
            if (!status.isVisible) {
              this.showPopup = false;
            }
          }
        })
        .onClick(() => {
          this.showPopup = true;
        })

        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          Image($r('app.media.eraser_line'))
            .height(20)
            .width(20)
        }
        .height(36)
        .width(36)
        .onClick(() => {
          this.gridDialog = new CustomDialogController({
            builder: MessageDialog({
              message: $r('app.string.delete_most_used_func_or_not'),
              onConfirm: () => {
                FunctionOrder.resetFunc();
                FunctionOrder.refreshFunc(); // 刷新点击次数显示
                this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
              }
            }),
            autoCancel: true,
            gridCount: 4
          });
          this.gridDialog.open();
        })
      }
      .height(40)
      .padding({ top: '10vp', left: '15vp', right: '10vp' })
      .clip(false)
      .width('100%')

      Grid() {
        ForEach(this.gridData, (item: MultiLink, index: number) => { // index: 当前GridComponent的索引
          GridItem() {
            Column() {
              Image(FunctionOrder.gIndex_to_pic(-1, index))
                .objectFit(ImageFit.Contain)
                .width('40vp')
                .height('40vp')
                .draggable(false)
              Text(item.title)
                .fontSize('12fp')
                .textAlign(TextAlign.Center)
                .margin({ top: '4vp' })
                .height('17vp')
            }
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .focusable(false)
          .height('64vp')
          .gesture(LongPressGesture()
            .onAction((event: GestureEvent | undefined) => {
              if (!event)
                return;

              if (FunctionOrder.order.length <= index) {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.try_to_custom_empty') });
              } else {
                let preName: string = FunctionOrder.order[index][0];
                if (preName != undefined) {
                  this.gridDialog = new CustomDialogController({
                    builder: CustomClickDialog({
                      gridIndex: Number(preName.split('.')[0]),
                      index: Number(preName.split('.')[1]),
                      copyMostUsedFunc: this.copyMostUsedFunc
                    }),
                    autoCancel: false,
                    gridCount: 4
                  });
                  this.gridDialog.open();
                }
              }
            })
          )
          .onClick(() => {
            if (FunctionOrder.order.length <= index) {
              this.getUIContext().getPromptAction().showToast({
                message: $r('app.string.click_empty_gridData' + tools.getRandomInt(1, 5).toString()),
                // 在 string.ets 里添加时别忘了改 tools.getRandomInt(1, 5)！！
                duration: 500
              });
            } else {
              let preName: string = FunctionOrder.order[index][0];
              if (preName) {
                const preGridIndex = Number(preName.split('.')[0]);
                const preIndex = Number(preName.split('.')[1]);
                this.openMultiLink(LINK[preGridIndex].set[preIndex], preGridIndex, preIndex);
                this.copyMostUsedFunc = FunctionOrder.mostUsedFunc;
              }
            }
          })
        },(item:string,index:number)=>index+JSON.stringify(item))
      }
      .padding(12)
      .rowsGap('8vp')
      .scrollBar(BarState.Off)
      .columnsTemplate('repeat(auto-fit, 70)');
    }
    .margin({ bottom: '8vp' })
    .borderRadius(20)
    .backgroundBlurStyle(BackgroundImage.blurLevel)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : '#0000')
  }


  @State showPopup: boolean = false;
  @Builder frequencyPopup() {
    Row() {
      Popup({
        message: { text: $r('app.string.help0_content_brief') },
        showClose: false,
        buttons: [{
          text: $r('app.string.close_this_hint'),
          action: () => {
            this.showPopup = false;
          }
        }]
      })
    }
  }

  openMultiLink(linkDetail: MultiLink, gridIndex: number, linkIndex: number) {
    // 记录并刷新点击次数
    // webName.push(LINK.get(preName)?.title ?? 'blank');
    resetWebName(linkDetail.title);
    FunctionOrder.recordClick(gridIndex, linkIndex);
    FunctionOrder.refreshFunc();

    // 打开对应页面，如果是多页面就弹出对话框
    if (linkDetail.url.length === 1) {
      pushRedirect(this.pageInfo, linkDetail.url[0], linkDetail.title as string)
    } else if (linkDetail.url.length > 1) { // 防止为空
      this.gridDialog = new CustomDialogController({
        builder: linkPickerDialog({
          gridIndex: gridIndex,
          index: linkIndex,
          pageInfo: this.pageInfo
        }),
        autoCancel: true,
        gridCount: 3
      });
      this.gridDialog.open();
    }
  }
}