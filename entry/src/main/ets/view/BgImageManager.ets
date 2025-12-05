import { image } from "@kit.ImageKit";
import UnifiedPreferences from '../utils/UnifyPreference';

class BackgroundImage {
  pic: image.PixelMap | undefined = undefined;
  hostContext: Context | undefined = undefined;
  showImage: boolean = UnifiedPreferences.getBoolSync('ShowImage', false);
  readonly imgPath: string = '';

  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    this.hostContext = context;
    if (this.showImage === false)
      this.pic = undefined;
    else
      this.pic = await this.getPixmapFromMedia($r('app.media.nic'));
  }


  private async getPixmapFromMedia(resource: Resource) {
    let createPixelMap: image.PixelMap;
    try {
      const unit8Array = await this.hostContext!.resourceManager?.getMediaContent(resource.id);
      const imageSource = image.createImageSource(unit8Array.buffer.slice(0, unit8Array.buffer.byteLength));
      createPixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      });
      await imageSource.release();
      this.pic?.release();
    } catch (error) {
      console.error(`getPixmapFromMedia ERROR: [${error.code}] ${error.message}`);
      return;
    }
    return createPixelMap;
  }

  /**
   * 更改是否显示背景图片，设计中更改后需要重启，因此只需要改变 UnifiedPreferences
   * @param isShown true：显示，false：隐藏
   */
  changeShowStatus(isShown: boolean) {
    this.showImage = isShown;
    UnifiedPreferences.putSync('ShowImage', isShown);
  }

  // getPic(): image.PixelMap { return; }

  /**
   * 从图片选择器获取到的图片地址，复制到应用目录 this.imgPath 所储存的目录下，并调用 this.getPic 转换为PixelMap
   * @param imgDir 传入的图片地址
   */
  pickFile(imgDir: string) {
  }
}

export default new BackgroundImage();