import { image } from "@kit.ImageKit";
import UnifiedPreferences from '../utils/UnifyPreference';
import { fileIo, fileUri } from "@kit.CoreFileKit";

class BackgroundImage {
  pic: ResourceStr | undefined = undefined;
  hostContext: Context | undefined = undefined;
  showImage: boolean = UnifiedPreferences.getBoolSync('ShowImage', false); // 是否展示
  readonly imgPath: string = UnifiedPreferences.getSync('ImagePath', ''); // 图片路径
  basicDir: string = '/data/storage/el2/base/files';

  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    this.hostContext = context;
    if (this.imgPath === '')
      this.showImage = false;
    if (!this.showImage)
      this.pic = undefined;
    else
      this.pic = fileUri.getUriFromPath(this.imgPath);
    this.basicDir = context.filesDir;
  }

  /**
   * 更改是否显示背景图片，设计中更改后需要重启，因此只需要改变 UnifiedPreferences
   * @param isShown true：显示，false：隐藏
   */
  changeShowStatus(isShown: boolean) {
    this.showImage = isShown;
    UnifiedPreferences.putSync('ShowImage', isShown);
  }
}

export default new BackgroundImage();