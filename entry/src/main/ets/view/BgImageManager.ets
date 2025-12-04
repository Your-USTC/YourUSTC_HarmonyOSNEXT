import { image } from "@kit.ImageKit";
import UnifiedPreferences from '../utils/UnifyPreference';

class BackgroundImage {
  pic: image.PixelMap | undefined = undefined;
  hostContext: Context | undefined = undefined;
  imgPath: string = UnifiedPreferences.getSync('bgImage', 'null');

  async init(context: Context) {
    this.hostContext = context;
    if (this.imgPath === 'null')
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
}

export default new BackgroundImage();