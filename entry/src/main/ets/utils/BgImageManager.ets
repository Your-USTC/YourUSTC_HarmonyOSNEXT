
import UnifiedPreferences from './UnifyPreference';
import { fileIo, fileUri, ListFileOptions } from "@kit.CoreFileKit";
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';

export interface iPresetColor {
  lightBgColor: string;
  darkBgColor: string;
  accentColor: string;
  name: string;
}

// [浅色标题背景，深色标题背景，通用按钮和进度条背景]
export const presetColor: iPresetColor[] = [
  { lightBgColor: '#BEDCF0', darkBgColor: '#102542', accentColor: '#4A90E2', name: '冰山蓝调'},
  { lightBgColor: '#D7CDF0', darkBgColor: '#2A3166', accentColor: '#6B5B9A', name: '深海回音'},
  { lightBgColor: '#E6E6FA', darkBgColor: '#4B0082', accentColor: '#9B6BB6', name: '薰衣草田'},
  { lightBgColor: '#ECEFF1', darkBgColor: '#263238', accentColor: '#5F7A8A', name: '冷石流云'},
  { lightBgColor: '#F8F9FA', darkBgColor: '#202124', accentColor: '#5F6368', name: '纸墨绘世'},
  { lightBgColor: '#F5D7D7', darkBgColor: '#A11616', accentColor: '#D81B60', name: '桃启绯英'},
  { lightBgColor: '#FFF0F6', darkBgColor: '#831843', accentColor: '#EC407A', name: '樱吹甜心'},
  { lightBgColor: '#FFD1D1', darkBgColor: '#822727', accentColor: '#B84D4D', name: '雪映残梅'},
  { lightBgColor: '#FFF4E0', darkBgColor: '#8B4513', accentColor: '#C37B4A', name: '古卷檀香'},
  { lightBgColor: '#FFDAB9', darkBgColor: '#B94E2E', accentColor: '#E07A4F', name: '落日熔金'},
  { lightBgColor: '#FFF9C4', darkBgColor: '#F57F17', accentColor: '#F9A825', name: '流光掠影'},
  { lightBgColor: '#FAFAD2', darkBgColor: '#7A5B00', accentColor: '#B8860B', name: '雨润杏帘'},
  { lightBgColor: '#BEF0C8', darkBgColor: '#556B2F', accentColor: '#7C9C5E', name: '森屿青柠'},
  { lightBgColor: '#F0FFF0', darkBgColor: '#1B5E20', accentColor: '#4C8B4C', name: '竹林月夜'},
  { lightBgColor: '#E0F7FA', darkBgColor: '#006064', accentColor: '#2C8B9A', name: '青琉碧落'}
];

// 深色模式下背景图的目标平均亮度（0-255）与自动调节系数下限
const DARK_TARGET_LUMINANCE: number = 90;
const DARK_MIN_FACTOR: number = 0.3;

/**
 * 解析'#RRGGBB'格式的颜色字符串
 * @returns [r, g, b] 分量数组，各分量取值0-255
 */
function hexToRgb(hex: string): number[] {
  const value: number = parseInt(hex.slice(1), 16);
  return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF];
}

/**
 * RGB分量（0-255）转'#RRGGBB'颜色字符串
 */
function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (v: number): string => {
    const hex: string = Math.round(Math.min(255, Math.max(0, v))).toString(16);
    return hex.length === 1 ? `0${hex}` : hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/**
 * RGB（0-255）转HSL，h/s/l分量取值均为0-1
 */
function rgbToHsl(r: number, g: number, b: number): number[] {
  const rn: number = r / 255;
  const gn: number = g / 255;
  const bn: number = b / 255;
  const max: number = Math.max(rn, gn, bn);
  const min: number = Math.min(rn, gn, bn);
  const l: number = (max + min) / 2;
  let h: number = 0;
  let s: number = 0;
  if (max !== min) {
    const d: number = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === rn)
      h = (gn - bn) / d + (gn < bn ? 6 : 0);
    else if (max === gn)
      h = (bn - rn) / d + 2;
    else
      h = (rn - gn) / d + 4;
    h /= 6;
  }
  return [h, s, l];
}

/**
 * HSL（h/s/l分量取值0-1）转'#RRGGBB'颜色字符串
 */
function hslToHex(h: number, s: number, l: number): string {
  const clampedL: number = Math.min(1, Math.max(0, l));
  const clampedS: number = Math.min(1, Math.max(0, s));
  const q: number = clampedL < 0.5 ? clampedL * (1 + clampedS) : clampedL + clampedS - clampedL * clampedS;
  const p: number = 2 * clampedL - q;
  const channel = (t: number): number => {
    let tn: number = t;
    if (tn < 0)
      tn += 1;
    if (tn > 1)
      tn -= 1;
    if (tn < 1 / 6)
      return p + (q - p) * 6 * tn;
    if (tn < 1 / 2)
      return q;
    if (tn < 2 / 3)
      return p + (q - p) * (2 / 3 - tn) * 6;
    return p;
  };
  return rgbToHex(channel(h + 1 / 3) * 255, channel(h) * 255, channel(h - 1 / 3) * 255);
}

// 自定义取色主题的缺省值：从未提取过主色时色环与各处主题色展示该缺省配色
const CUSTOM_PRESET_DEFAULT: iPresetColor = {
  lightBgColor: '#F0F4F8', darkBgColor: '#1C2833', accentColor: '#78909C', name: '图色天成'// 自定义色/随心取色/画境随心
};

/**
 * 自定义取色主题项：字段为@Trace，提取主色后全应用读取这些颜色的UI即时刷新
 */
@ObservedV2
class CustomPresetColor implements iPresetColor {
  @Trace lightBgColor: string = CUSTOM_PRESET_DEFAULT.lightBgColor;
  @Trace darkBgColor: string = CUSTOM_PRESET_DEFAULT.darkBgColor;
  @Trace accentColor: string = CUSTOM_PRESET_DEFAULT.accentColor;
  @Trace name: string = CUSTOM_PRESET_DEFAULT.name;
}

export const customPreset: CustomPresetColor = new CustomPresetColor();
presetColor.push(customPreset);
// 自定义取色项固定在presetColor末尾，持久化的ThemeColor索引可能指向它
export const customPresetIndex: number = presetColor.length - 1;

// 响应式单例：字段变化直接刷新全应用读取这些字段的UI（设置页热更新的基础）
@ObservedV2
class BackgroundImage {
  @Trace pic: ResourceStr | undefined = undefined;
  @Trace showImage: boolean = false; // 是否展示
  @Trace imgPath: string = ''; // 图片路径
  basicDir: string = '/data/storage/el2/base/files';
  @Trace blurLevel: BlurStyle | undefined = undefined;
  @Trace opacityLevel: number = 1;
  @Trace backgroundBlur: boolean = true; // 选择背景模糊
  @Trace themeColor: number = 0;
  @Trace autoDecBright: boolean = true; // 深色模式自动降低背景亮度
  @Trace brightness: number = 1;
  @Trace effectiveBrightness: number = 1; // 实际显示亮度，深色模式自动调节后可能小于手动亮度
  @Trace avgBrightness: number = -1; // 图片平均亮度（0-255），-1表示未测量
  @Trace darkMode: boolean = false; // 是否处于深色模式，init/syncDarkMode时确定
  @Trace colorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  /**
   * 标题栏背景色：按当前主题索引与深浅色模式取presetColor对应列，索引钳制防越界。
   * themeColor与darkMode均为@Trace，主题或深浅色变化时UI自动刷新
   */
  get titleBackgroundColor(): string {
    const index: number = Math.min(presetColor.length - 1, Math.max(0, Math.trunc(this.themeColor)));
    return this.darkMode ? presetColor[index].darkBgColor : presetColor[index].lightBgColor;
  }

  @Trace avatar: ResourceStr = $r('app.media.avatar_placeholder');
  avatarPath: string = '';
  /**
   * 初始化
   * @param context 传入上下文
   */
  async init(context: Context) {
    // 变量初始化
    this.showImage = UnifiedPreferences.getBoolSync('ShowImage', false);
    this.imgPath = UnifiedPreferences.getSync('ImagePath', '');
    this.backgroundBlur = UnifiedPreferences.getBoolSync('BackgroundBlur', true);
    this.themeColor = UnifiedPreferences.getNumberSync('ThemeColor', 0);
    this.restoreCustomPreset();
    this.autoDecBright = UnifiedPreferences.getBoolSync('AutoDecBright', true);
    this.avgBrightness = UnifiedPreferences.getNumberSync('ImageAvgBrightness', -1);
    this.colorMode = UnifiedPreferences.getNumberSync('ColorMode', ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    this.avatarPath = UnifiedPreferences.getSync('AvatarPath', '');

    // 路径检验
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

  /**
   * 提取图片主色调：下采样解码后用effectKit创建ColorPicker，
   * getMainColor通过图像缩放算法将原图缩小到1像素加权计算得到主色
   * @param filePath 图片完整路径
   * @returns 主色调Color（RGBA分量各0-255），失败时抛出异常
   */
  async extractMainColor(filePath: string): Promise<effectKit.Color> {
    const imageSource: image.ImageSource = image.createImageSource(filePath);
    try {
      // 下采样解码，主色计算无需原图分辨率，显著减少内存占用
      const decodingOptions: image.DecodingOptions = {
        desiredSize: { width: 200, height: 200 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      };
      const pixelMap: image.PixelMap = await imageSource.createPixelMap(decodingOptions);
      try {
        const colorPicker: effectKit.ColorPicker = await effectKit.createColorPicker(pixelMap);
        return await colorPicker.getMainColor();
      } finally {
        await pixelMap.release();
      }
    } finally {
      await imageSource.release();
    }
  }

  /**
   * 用提取到的主色更新自定义取色主题项（HSL变换派生深浅背景色）：
   * 适中色（accentColor）为主色本身；
   * 浅色背景提高明度、略降饱和度：L_light = L + (1 - L) * 0.65，S_light = S * 0.85；
   * 深色背景降低明度、略升饱和度：L_dark = L * 0.45，S_dark = min(1, S * 1.1)
   * @param r 主色红色分量（0-255）
   * @param g 主色绿色分量（0-255）
   * @param b 主色蓝色分量（0-255）
   */
  applyCustomThemeColor(r: number, g: number, b: number) {
    const hsl: number[] = rgbToHsl(r, g, b);
    const h: number = hsl[0];
    const s: number = hsl[1];
    const l: number = hsl[2];
    customPreset.accentColor = rgbToHex(r, g, b);
    customPreset.lightBgColor = hslToHex(h, s * 0.85, l + (1 - l) * 0.65);
    customPreset.darkBgColor = hslToHex(h, Math.min(1, s * 1.1), l * 0.45);
  }

  /**
   * 从持久化设置恢复自定义取色主题项：应用初始化与退出主题设置页时调用，
   * 保证自定义项与最后一次应用的取色一致（未应用的提取结果随离开设置页作废）
   */
  restoreCustomPreset() {
    const accent: string = UnifiedPreferences.getSync('CustomThemeAccent', '');
    if (accent !== '') {
      const rgb: number[] = hexToRgb(accent);
      this.applyCustomThemeColor(rgb[0], rgb[1], rgb[2]);
    } else {
      customPreset.lightBgColor = CUSTOM_PRESET_DEFAULT.lightBgColor;
      customPreset.darkBgColor = CUSTOM_PRESET_DEFAULT.darkBgColor;
      customPreset.accentColor = CUSTOM_PRESET_DEFAULT.accentColor;
    }
  }
}

export default new BackgroundImage();