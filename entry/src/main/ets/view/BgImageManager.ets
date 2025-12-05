
import UnifiedPreferences from '../utils/UnifyPreference';
import { fileUri } from "@kit.CoreFileKit";

class BackgroundImage {
  pic: ResourceStr | undefined = undefined;
  hostContext: Context | undefined = undefined;
  showImage: boolean = UnifiedPreferences.getBoolSync('ShowImage', false); // 是否展示
  readonly imgPath: string = UnifiedPreferences.getSync('ImagePath', ''); // 图片路径
  basicDir: string = '/data/storage/el2/base/files';
  blurLevel: BlurStyle | undefined = undefined;

  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    this.hostContext = context;
    if (this.imgPath === '')
      this.showImage = false;
    if (!this.showImage) {
      this.pic = undefined;
      this.blurLevel = undefined;
    }
    else {
      this.pic = fileUri.getUriFromPath(this.imgPath);
      this.blurLevel = UnifiedPreferences.getNumberSync('BlurLevel', BlurStyle.COMPONENT_REGULAR);
    }
    this.basicDir = context.filesDir;
  }
}

export default new BackgroundImage();