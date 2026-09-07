
import UnifiedPreferences from './UnifyPreference';
import { fileIo, fileUri, ListFileOptions } from "@kit.CoreFileKit";
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

// [浅色标题背景，深色标题背景，通用按钮和进度条背景]
export const presetColor: string[][] = [
  ['#BEDCF0', '#102542', '#4A90E2', '冰山蓝调'],
  ['#D7CDF0', '#2A3166', '#6B5B9A', '深海回音'],
  ['#E6E6FA', '#4B0082', '#9B6BB6', '薰衣草田'],
  ['#ECEFF1', '#263238', '#5F7A8A', '冷石流云'],
  ['#F8F9FA', '#202124', '#5F6368', '纸墨绘世'],
  ['#F5D7D7', '#A11616', '#D81B60', '桃启绯英'],
  ['#FFF0F6', '#831843', '#EC407A', '樱吹甜心'],
  ['#FFD1D1', '#822727', '#B84D4D', '雪映残梅'],
  ['#FFF4E0', '#8B4513', '#C37B4A', '古卷檀香'],
  ['#FFDAB9', '#B94E2E', '#E07A4F', '落日熔金'],
  ['#FFF9C4', '#F57F17', '#F9A825', '流光掠影'],
  ['#FAFAD2', '#7A5B00', '#B8860B', '雨润杏帘'],
  ['#BEF0C8', '#556B2F', '#7C9C5E', '森屿青柠'],
  ['#F0FFF0', '#1B5E20', '#4C8B4C', '竹林月夜'],
  ['#E0F7FA', '#006064', '#2C8B9A', '青琉碧落']
];

// 深色模式下背景图的目标平均亮度（0-255）与自动调节系数下限
const DARK_TARGET_LUMINANCE: number = 90;
const DARK_MIN_FACTOR: number = 0.3;

// 响应式单例：字段变化直接刷新全应用读取这些字段的UI（设置页热更新的基础）
@ObservedV2
class BackgroundImage {
  @Trace pic: ResourceStr | undefined = undefined;
  @Trace showImage: boolean = UnifiedPreferences.getBoolSync('ShowImage', false); // 是否展示
  @Trace imgPath: string = UnifiedPreferences.getSync('ImagePath', ''); // 图片路径
  basicDir: string = '/data/storage/el2/base/files';
  @Trace blurLevel: BlurStyle | undefined = undefined;
  @Trace opacityLevel: number = 1;
  @Trace backgroundBlur: boolean = UnifiedPreferences.getBoolSync('BackgroundBlur', true); // 选择背景模糊
  @Trace themeColor: number = UnifiedPreferences.getNumberSync('ThemeColor', 0);
  @Trace autoDecBright: boolean = UnifiedPreferences.getBoolSync('AutoDecBright', true); // 深色模式自动降低背景亮度
  @Trace brightness: number = 1;
  @Trace effectiveBrightness: number = 1; // 实际显示亮度，深色模式自动调节后可能小于手动亮度
  @Trace avgBrightness: number = UnifiedPreferences.getNumberSync('ImageAvgBrightness', -1); // 图片平均亮度（0-255），-1表示未测量
  @Trace darkMode: boolean = false; // 是否处于深色模式，init/syncDarkMode时确定
  @Trace colorMode: number = UnifiedPreferences.getNumberSync('ColorMode', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

  @Trace avatar: ResourceStr = $r('app.media.avatar_placeholder');
  avatarPath: string = UnifiedPreferences.getSync('AvatarPath', '');
  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    try {
      if (this.imgPath === '' || !fileIo.accessSync(this.imgPath))
        this.showImage = false;
    } catch {
      this.showImage = false;
    }
    this.syncDarkMode(context);
    if (this.showImage && this.avgBrightness < 0) {
      // 旧版本设置的图片没有亮度记录，后台补测一次并缓存
      this.updateAvgBrightness(this.imgPath);
    }

    if (this.avatarPath !== '') {
      this.avatar = fileUri.getUriFromPath(this.avatarPath);
    }
    this.basicDir = context.filesDir;
    this.refreshDisplay();
  }

  /**
   * 同步深色模式缓存。手动 setColorMode 后收不到 onConfigurationUpdate，
   * 热更新颜色模式后需调用此方法刷新 darkMode 供自动降亮等逻辑判断
   * @param context 上下文，仅"跟随系统"时用于读取当前配置
   */
  syncDarkMode(context: Context) {
    if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
      this.darkMode = true;
    else if (this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
      this.darkMode = false;
    else {
      try {
        this.darkMode = context.getApplicationContext().resourceManager.getConfigurationSync().colorMode
          === resourceManager.ColorMode.DARK;
      } catch {
        this.darkMode = false;
      }
    }
  }

  /**
   * 依据当前字段值与持久化设置重算显示状态（图片、模糊/透明互斥、有效亮度）。
   * 启动初始化与设置热更新共用：热更新前需先持久化并同步字段值
   */
  refreshDisplay() {
    if (this.showImage) {
      this.pic = fileUri.getUriFromPath(this.imgPath);
      if (this.backgroundBlur) { // 如果选择背景模糊
        this.blurLevel = UnifiedPreferences.getNumberSync('BlurLevel', BlurStyle.COMPONENT_REGULAR);
        this.opacityLevel = 1;
      } else { // 如果选择背景透明
        this.blurLevel = undefined;
        this.opacityLevel = UnifiedPreferences.getNumberSync('OpacityLevel', 100) / 100;
      }
      this.brightness = UnifiedPreferences.getNumberSync('BackgroundBrightness', 100) / 100;
      this.effectiveBrightness = this.brightness * this.autoBrightFactor(this.avgBrightness, this.autoDecBright);
    } else {
      this.pic = undefined;
      this.blurLevel = undefined;
      this.opacityLevel = 1;
    }
  }

  /**
   * 清理除保留路径外的背景图文件（背景图文件名带时间戳，替换后需删除旧文件）
   * @param keepPath 保留的背景图完整路径
   */
  cleanBackgroundFiles(keepPath: string) {
    try {
      const listFileOption: ListFileOptions = {
        filter: { displayName: ['backgroundImage*'] }
      };
      fileIo.listFileSync(this.basicDir, listFileOption).forEach((value) => {
        const filePath = `${this.basicDir}/${value}`;
        if (filePath !== keepPath) {
          try {
            fileIo.unlinkSync(filePath);
          } catch (e) {
            console.error('Failed to delete old background image');
          }
        }
      });
    } catch (e) {
      console.error('Failed to list background images');
    }
  }

  deleteBackgroundImage() {
    if (this.imgPath !== '' && fileIo.accessSync(this.imgPath)) {
      try {
        fileIo.unlinkSync(this.imgPath);
      } catch (e) {
        console.error('Failed to delete file');
      }
    }
    this.imgPath = '';
    this.showImage = false;
    this.avgBrightness = -1;
    UnifiedPreferences.putSync('ImagePath', '', false);
    UnifiedPreferences.putSync('ShowImage', false, false);
    UnifiedPreferences.putSync('ImageAvgBrightness', -1, false);
    UnifiedPreferences.flush();
  }

  async pickAvatar() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris[0] !== undefined) {
        // 删除旧的
        const listFileOption: ListFileOptions = {
          filter: { displayName: ['avatarImage_*'] }
        };
        fileIo.listFileSync(this.basicDir, listFileOption).forEach((value, index) => {
          fileIo.unlinkSync(`${this.basicDir}/${value}`);
        });
        const oriImgPath = new fileUri.FileUri(photoSelectResult.photoUris[0]).path;
        this.avatarPath = this.basicDir + `/avatarImage_${Date.now()}`;
        fileIo.copyFileSync(oriImgPath, this.avatarPath);
        this.avatar = fileUri.getUriFromPath(this.avatarPath);
        UnifiedPreferences.putSync('AvatarPath', this.avatarPath);
      }
    } catch (error) {
      console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
    }
  }

  deleteAvatar() {
    if (this.avatarPath !== '') {
      try {
        fileIo.unlinkSync(this.avatarPath);
      } catch (e) {
        console.error('Failed to delete file');
      }
    }
    this.avatar = $r('app.media.avatar_placeholder');
    UnifiedPreferences.putSync('AvatarPath', '');
  }

  /**
   * 计算深色模式下的亮度调节系数：图片越亮降得越多，本身足够暗的图片不调节
   * @param avgBrightness 图片平均亮度（0-255），未测量时传-1
   * @param enabled 是否启用自动降低亮度
   * @returns 亮度系数（DARK_MIN_FACTOR到1之间），浅色模式或未启用时返回1
   */
  autoBrightFactor(avgBrightness: number, enabled: boolean): number {
    if (!enabled || !this.darkMode || avgBrightness < 0)
      return 1;
    return Math.max(DARK_MIN_FACTOR, Math.min(1, DARK_TARGET_LUMINANCE / avgBrightness));
  }

  /**
   * 测量图片平均亮度并持久化，完成后重算显示状态使自动亮度即时生效
   */
  async updateAvgBrightness(filePath: string): Promise<void> {
    try {
      this.avgBrightness = await this.calculateBrightnessByDownSample(filePath);
      UnifiedPreferences.putSync('ImageAvgBrightness', this.avgBrightness);
      this.refreshDisplay();
    } catch (error) {
      console.error(`Failed to calculate image brightness: ${JSON.stringify(error)}`);
    }
  }

  async calculateBrightnessByDownSample(filePath: string): Promise<number> {
    // 创建ImageSource
    const imageSource: image.ImageSource = image.createImageSource(filePath);

    try {
      // 设置下采样参数，将图片缩小到最大200x200，显著减少内存占用
      const decodingOptions: image.DecodingOptions = {
        desiredSize: { width: 200, height: 200 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      };

      // 异步创建PixelMap
      const pixelMap: image.PixelMap = await imageSource.createPixelMap(decodingOptions);

      try {
        // 获取图片信息
        const imageInfo: image.ImageInfo = await pixelMap.getImageInfo();
        const width: number = imageInfo.size.width;
        const height: number = imageInfo.size.height;

        // 准备像素缓冲区，readPixels对非YUV格式按BGRA_8888存入，每像素4字节
        const bufferSize: number = width * height * 4;
        const buffer: ArrayBuffer = new ArrayBuffer(bufferSize);
        const area: image.PositionArea = {
          pixels: buffer,
          offset: 0,
          stride: width * 4, // 每行字节数
          region: { size: { width: width, height: height }, x: 0, y: 0 }
        };

        // 读取全部像素数据
        await pixelMap.readPixels(area);

        // 计算平均亮度
        const pixelData: Uint8Array = new Uint8Array(buffer);
        let totalBrightness: number = 0;
        const pixelCount: number = width * height;

        for (let i: number = 0; i < pixelCount; i++) {
          const base: number = i * 4;
          // BGRA_8888格式：B在前，G其次，R再次，A最后
          const b: number = pixelData[base];
          const g: number = pixelData[base + 1];
          const r: number = pixelData[base + 2];
          // ITU-R BT.601 亮度公式
          const brightness: number = 0.299 * r + 0.587 * g + 0.114 * b;
          totalBrightness += brightness;
        }

        const averageBrightness: number = totalBrightness / pixelCount;
        console.info(`平均亮度: ${averageBrightness.toFixed(2)}`);
        return averageBrightness;
      } finally {
        // 确保释放PixelMap内存
        await pixelMap.release();
      }
    } finally {
      // 确保释放ImageSource内存
      await imageSource.release();
    }
  }
}

export default new BackgroundImage();