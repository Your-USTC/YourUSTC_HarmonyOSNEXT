
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import UnifiedPreferences from '../utils/UnifyPreference';
import BackgroundImage, { iPresetColor, presetColor } from '../utils/BgImageManager';

@Builder
export function ThemeBuilder(name: string, param?: number[]) {
  if (param)
    ThemeSetting({ windowWidth: param[0], windowHeight: param[1] });
  else
    ThemeSetting();
}

function BlurStyleToNum(ori: BlurStyle | undefined): number {
  switch (ori) {
    case BlurStyle.NONE:
      return 0;
    case BlurStyle.COMPONENT_ULTRA_THIN:
      return 1;
    case BlurStyle.COMPONENT_THIN:
      return 2;
    case BlurStyle.COMPONENT_REGULAR:
      return 3;
    case BlurStyle.COMPONENT_THICK:
      return 4;
    case BlurStyle.COMPONENT_ULTRA_THICK:
      return 5;
    default:
      return 3;
  }
}

/**
 * 计算环形进度条的进度
 * @param n 进度条总数
 * @param given 已知进度为50%的编号
 * @param target 目标编号
 * @returns 进度值（0-100之间的数字）
 */
function calculateProgress(n: number, given: number, target: number): number {
  const delta = ((target - given) % n + n) % n;
  const step = 200 / n;
  const quarter = n / 4;
  const threeQuarter = 3 * n / 4;
  let progress: number;
  if (delta >= 0 && delta < quarter) {
    progress = 50 - delta * step;
  } else if (delta >= quarter && delta < threeQuarter) {
    progress = (delta - quarter) * step;
  } else {
    progress = 100 - (delta - threeQuarter) * step;
  }
  return Math.max(0, Math.min(100, progress));
}

const diameter: number = 35;
const distance: number = 90;
const halfSize: number = (diameter >> 1) + distance + 10;
const colorNum: number = presetColor.length;

function posToIndex(x: number, y: number): number {
  let angle = Math.atan2(x - halfSize, halfSize - y);
  if (angle < 0)
    angle += 2 * Math.PI;
  angle += Math.PI / colorNum;
  return Math.trunc(angle * colorNum / (2 * Math.PI)) % colorNum;
}

@Entry
@Component
struct ThemeSetting {

  @State sliderNum: number = BlurStyleToNum(BackgroundImage.blurLevel); // 模糊程度滑动条参数
  @State opacityNum: number = UnifiedPreferences.getNumberSync('OpacityLevel', 100); // 不透明度
  @State isShown: boolean = BackgroundImage.showImage; // 显示预览图片
  @State imgPreview: ResourceStr = (BackgroundImage.imgPath == '') ? $r('app.media.confused') : fileUri.getUriFromPath(BackgroundImage.imgPath); //预览图片
  @State blurNum: BlurStyle = UnifiedPreferences.getNumberSync('BlurLevel', BlurStyle.COMPONENT_REGULAR); // 模糊程度常数
  @State imgBrightness: number = UnifiedPreferences.getNumberSync('BackgroundBrightness', 100);
  private selectResult: string | undefined = undefined; // 选择图片的结果
  private oriImgPath: string = ''; // 原始图片路径
  private imageSize: number = 0; // 图片文件大小
  @State showBlurSlider: boolean = BackgroundImage.backgroundBlur;
  @State autoDecBright: boolean = BackgroundImage.autoDecBright;
  @State pickedAvgBrightness: number = -1; // 新选图片的平均亮度，未测量时为-1
  windowWidth: number = 1840;
  windowHeight: number = 2800;
  @State showWarning: boolean = false;

  @State colorMode: number = BackgroundImage.colorMode;
  @State adaptSplit: number = UnifiedPreferences.getNumberSync('AdaptSplit', NavigationMode.Auto);

  @State selectedColor: number = BackgroundImage.themeColor;
  readonly singleRotate: number = 360 / colorNum;

  pathStack: NavPathStack = new NavPathStack();
  menuItems: Array<NavigationMenuItem> = [
    {
      value: $r('app.string.ok_and_apply'),
      icon: $r('app.media.checkmark'),
      action: () => {
        this.confirmAndApply();
      }
    }
  ];

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Column() {
            Row({ space: 5 }) {
              Image($r('app.media.shutter_photo'))
                .height(30);
              Text($r('app.string.custom_background'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold);
              Divider()
                .layoutWeight(1);
              Toggle({ isOn: $$this.isShown, type: ToggleType.Switch })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .onChange((value: boolean) => {
                  if (BackgroundImage.imgPath == '' && this.selectResult == undefined && value) {
                    this.isShown = false;
                    this.SelectImage();
                  }
                });
            }
            .padding(8)
            .width('100%')

            Stack() {
              Image(this.isShown ? this.imgPreview : $r('app.media.suspect'))
                .alt($r('app.media.suspect'))
                .width('100%')
                .height(this.isShown ? undefined : 180)
                .constraintSize({ minHeight: 80, maxHeight: 360 })
                .borderRadius(16)
                .objectFit(ImageFit.Contain)
                .opacity(this.isShown ? this.imgBrightness / 100 * this.previewBrightnessFactor() : 1)
                .autoResize(true)
                .interpolation(ImageInterpolation.Medium)
                .animation({
                  duration: 500,
                  curve: Curve.Ease
                })
                .onComplete((value) => {
                  if (value !== undefined) {
                    let swapTemp: number;
                    if (value.width > value.height) {
                      swapTemp = value.width;
                      value.width = value.height;
                      value.height = swapTemp;
                    }
                    if (value.width > this.windowWidth * 3 || value.height > this.windowHeight * 3 || this.imageSize > 50000000) {
                      this.showWarning = true;
                    } else {
                      this.showWarning = false;
                    }
                  } else {
                    this.showWarning = false;
                  }
                })

              Button($r('app.string.pick_image'))
                .buttonStyle(ButtonStyleMode.NORMAL)
                .backgroundBlurStyle(this.showBlurSlider ? this.blurNum : undefined)
                .opacity(this.showBlurSlider ? 1 : this.opacityNum / 100)
                .onClick(() => {
                  this.SelectImage();
                })
            }
            .margin({ bottom: 5 })
            .padding({ left: 16, right: 16 })

            Row() {
              Text($r('app.string.background_opaque'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .fontWeight(this.showBlurSlider ? FontWeight.Normal : FontWeight.Bold)
              Toggle({ isOn: $$this.showBlurSlider, type: ToggleType.Switch })
                .switchStyle({ unselectedColor: presetColor[BackgroundImage.themeColor].accentColor })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
              Text($r('app.string.background_blur'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .fontWeight(this.showBlurSlider ? FontWeight.Bold : FontWeight.Normal)

              Select([{ value: '不透明' }, { value: '半透明' }, { value: '带模糊' }, { value: '纯享版' }, { value: '全覆盖' } ])
                .controlSize(ControlSize.SMALL)
                .value('选预设')
                .onSelect((index: number) => {
                  switch (index) {
                    case 0:
                      this.showBlurSlider = false;
                      this.opacityNum = 100;
                      this.imgBrightness = 100;
                      break;
                    case 1:
                      this.showBlurSlider = false;
                      this.opacityNum = 85;
                      this.imgBrightness = 100;
                      break;
                    case 2:
                      this.showBlurSlider = true;
                      this.blurNum = BlurStyle.COMPONENT_REGULAR;
                      this.sliderNum = 3;
                      break;
                    case 3:
                      this.showBlurSlider = true;
                      this.blurNum = BlurStyle.NONE;
                      this.sliderNum = 0;
                      this.autoDecBright = true;
                      break;
                    case 4:
                      this.showBlurSlider = false;
                      this.opacityNum = 25;
                      this.imgBrightness = 25;
                      this.autoDecBright = false;
                      break;
                  }
                })
            }
            .padding({ right: 16 })

            Row() {
              if (this.showBlurSlider) {
                Text($r('app.string.grid_background_blur'))
                Slider({
                  value: this.sliderNum,
                  min: 0,
                  max: 5,
                  step: 1,
                  style: SliderStyle.InSet
                })
                  .showSteps(true)
                  .layoutWeight(1)
                  .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                  .onChange((value: number) => {
                    this.sliderNum = value;
                    switch (value) {
                      case 0:
                        this.blurNum = BlurStyle.NONE;
                        break;
                      case 1:
                        this.blurNum = BlurStyle.COMPONENT_ULTRA_THIN;
                        break;
                      case 2:
                        this.blurNum = BlurStyle.COMPONENT_THIN;
                        break;
                      case 3:
                        this.blurNum = BlurStyle.COMPONENT_REGULAR;
                        break;
                      case 4:
                        this.blurNum = BlurStyle.COMPONENT_THICK;
                        break;
                      case 5:
                        this.blurNum = BlurStyle.COMPONENT_ULTRA_THICK;
                        break;
                    }
                  })
              } else {
                Text($r('app.string.grid_background_opacity'))
                Slider({
                  value: this.opacityNum,
                  min: 25,
                  max: 100,
                  step: 1,
                  style: SliderStyle.InSet
                })
                  .showTips(true, `${this.opacityNum}%`)
                  .layoutWeight(1)
                  .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                  .onChange((value: number) => {
                    this.opacityNum = value;
                  });
              }
            }
            .padding({ left: 16, right: 16 });

            Row() {
              Text($r('app.string.basic_brightness'));

              Slider({
                value: this.imgBrightness,
                min: 0,
                max: 100,
                step: 1,
                style: SliderStyle.InSet
              })
                .showSteps(false)
                .showTips(true)
                .layoutWeight(1)
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .onChange((value: number) => {
                  this.imgBrightness = value;
                });
            }
            .padding({ left: 16, right: 16 })

            Row() {
              Text($r('app.string.auto_decrease_background_brightness'))
                .layoutWeight(1)

              Toggle({ isOn: $$this.autoDecBright, type: ToggleType.Checkbox })
                .selectedColor(presetColor[BackgroundImage.themeColor].accentColor)
                .padding({ right: 16 })
            }
            .padding({ left: 16, right: 16 });

            Text($r('app.string.too_large_bg_image'))
              .fontColor($r('app.color.red'))
              .fontSize(15)
              .visibility(this.showWarning ? Visibility.Visible : Visibility.None);
          }
          .padding({ bottom: 6 })
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .borderRadius(23)

          Column() {
            Row() {
              Image($r('app.media.custom_theme_color'))
                .height(30)
                .margin({ right: 5 });
              Text($r('app.string.custom_theme_color'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .fontColor('#000');
              Text(presetColor[this.selectedColor].name)
                .fontSize(16)
                .margin({ right: 7 })
                .fontColor('#fff');
            }
            .padding(8)
            .borderRadius(BackgroundImage.blurLevel === undefined ? 23 : undefined)
            .linearGradient({
              angle: 90,
              colors: [[presetColor[this.selectedColor].lightBgColor, 0.0], [presetColor[this.selectedColor].darkBgColor, 1.0]]
            })

            Text(this.isShown && this.showBlurSlider ? $r('app.string.custom_theme_color_into') : $r('app.string.click_slide_change_color'))
              .fontSize(13)
              .fontColor(this.isShown && this.showBlurSlider ? $r('app.color.red') : undefined)
              .padding({ left: 16, right: 16 })
              .textAlign(TextAlign.Center)
              .margin({ bottom: 5, top: 5 })

            Stack({ alignContent: Alignment.Center }) {
              ForEach(presetColor, (singleColor: iPresetColor, index: number) => {
                Progress({
                  value: calculateProgress(colorNum, this.selectedColor, index),
                  type: ProgressType.Eclipse
                })
                  .width(diameter)
                  .color(singleColor.lightBgColor)
                  .backgroundColor(singleColor.darkBgColor)
                  .offset({
                    x: distance * Math.sin(360 * index / colorNum * (Math.PI / 180)),
                    y: -distance * Math.cos(360 * index / colorNum * (Math.PI / 180))
                  })
                // .onTouch(() => {
                //   this.selectedColor = index;
                // })
              })

              Image($r('app.media.selected'))
                .width(diameter * 0.6)
                .height(diameter * 0.6)
                .offset({
                  x: distance * Math.sin(360 * this.selectedColor / colorNum * (Math.PI / 180)),
                  y: -distance * Math.cos(360 * this.selectedColor / colorNum * (Math.PI / 180))
                })

              // Toggle({ type: ToggleType.Switch, isOn: true }).selectedColor(presetColor[this.selectedColor][2])
            }
            .height(halfSize * 2)
            .width(halfSize * 2)
            .borderStyle(BorderStyle.Dotted)
            .borderWidth(1)
            .borderColor($r('app.color.normal_text'))
            .margin({ bottom: 6 })
            .gesture(
              GestureGroup(GestureMode.Exclusive,
                TapGesture()
                  .onAction((event: GestureEvent) => {
                    this.selectedColor = posToIndex(event.fingerList[0].localX, event.fingerList[0].localY);
                  }),
                PanGesture()
                  .onActionUpdate((event: GestureEvent) => {
                    this.selectedColor = posToIndex(event.fingerList[0].localX, event.fingerList[0].localY);
                  })
              )
            )
          }
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .borderRadius(BackgroundImage.blurLevel === undefined ? undefined : 23)
          .clip(true)

          Column() {
            Row({ space: 5 }) {
              Image($r('app.media.dark_mode'))
                .height(30);
              Text($r('app.string.change_dark_light_mode'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .padding(8)

            Column() {
              Row() {
                Image($r('app.media.brightness'))
                  .height(27)
                  .width(27)
                  .margin({ right: 12, left: 2 })
                Text($r('app.string.light'))
                  .layoutWeight(1)
                Image($r('app.media.selected'))
                  .visibility(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? Visibility.Visible : Visibility.Hidden)
                  .height(27)
                  .width(27)
              }
              .width('100%')
              .height(45)
              .onClick(() => {
                if (this.colorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
                  this.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
                  // this.getUIContext().getHostContext()?.getApplicationContext().setColorMode(this.colorMode);
                  // UnifiedPreferences.putSync('ColorMode', this.colorMode);
                }
              })

              Divider();
              Row() {
                Image($r('app.media.moon'))
                  .height(27)
                  .width(27)
                  .margin({ right: 12, left: 2 })
                Text($r('app.string.dark'))
                  .layoutWeight(1)
                Image($r('app.media.selected'))
                  .visibility(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? Visibility.Visible : Visibility.Hidden)
                  .height(27)
                  .width(27)
              }
              .width('100%')
              .height(45)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                if (this.colorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
                  this.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
                  // this.getUIContext().getHostContext()?.getApplicationContext().setColorMode(this.colorMode);
                  // UnifiedPreferences.putSync('ColorMode', this.colorMode);
                }
              })

              Divider();
              Row() {
                Image($r('app.media.follow_system'))
                  .height(27)
                  .width(27)
                  .margin({ right: 12, left: 2 })
                Text($r('app.string.follow_system'))
                  .layoutWeight(1)
                Image($r('app.media.selected'))
                  .visibility(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET ? Visibility.Visible : Visibility.Hidden)
                  .height(27)
                  .width(27)
              }
              .width('100%')
              .height(45)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                if (this.colorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
                  this.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
                  // this.getUIContext().getHostContext()?.getApplicationContext().setColorMode(this.colorMode);
                  // UnifiedPreferences.putSync('ColorMode', this.colorMode);
                }
              })
            }
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 10 })
          }
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .borderRadius(23)

          Column() {
            Row({ space: 5 }) {
              Image($r('app.media.rotate'))
                .height(30);
              Text($r('app.string.change_navigation_mode'))
                .fontSize(20)
                .fontWeight(FontWeight.Bold);
            }
            .width('100%')
            .padding(8)

            Column() {
              Row() {
                Image($r('app.media.resize'))
                  .height(27)
                  .width(27)
                  .margin({ right: 12, left: 2 })
                Text($r('app.string.adapt_window_width'))
                  .layoutWeight(1)
                Image($r('app.media.selected'))
                  .visibility(this.adaptSplit === NavigationMode.Auto ? Visibility.Visible : Visibility.Hidden)
                  .height(27)
                  .width(27)
              }
              .width('100%')
              .height(45)
              .onClick(() => {
                this.adaptSplit = NavigationMode.Auto;
              })

              Divider();
              Row() {
                Image($r('app.media.full_screen'))
                  .height(27)
                  .width(27)
                  .margin({ right: 12, left: 2 })
                Text($r('app.string.force_stack_mode'))
                  .layoutWeight(1)
                Image($r('app.media.selected'))
                  .visibility(this.adaptSplit === NavigationMode.Stack ? Visibility.Visible : Visibility.Hidden)
                  .height(27)
                  .width(27)
              }
              .width('100%')
              .height(45)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                this.adaptSplit = NavigationMode.Stack;
              })
            }
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 10 })
          }
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .borderRadius(23)
        }
        .padding(9)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .width('100%')
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
    }
    .title({ main: $r('app.string.theme_setting'), sub: $r('app.string.theme_setting_intro') }, {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: BackgroundImage.blurLevel === undefined ? BackgroundImage.titleBackgroundColor : '#0000'
    })
    .backButtonIcon($r('app.media.close'))
    .menus(this.menuItems)
    .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : '#0000')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }

  /**
   * 预览图应乘的自动亮度系数：深色模式且开启自动降低时按图片平均亮度调节
   * @returns 亮度系数，1表示不调节
   */
  previewBrightnessFactor(): number {
    const avgBrightness = this.selectResult !== undefined ? this.pickedAvgBrightness : BackgroundImage.avgBrightness;
    return BackgroundImage.autoBrightFactor(avgBrightness, this.autoDecBright);
  }

  /**
   * 应用并持久化全部设置。不重启应用：BackgroundImage 为响应式单例，
   * 持久化并同步字段后调用 refreshDisplay() 即可让全应用UI热更新
   */
  private async confirmAndApply(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 深浅色模式：setColorMode即时生效；手动设置后收不到onConfigurationUpdate，需手动同步darkMode缓存
    if (this.colorMode !== BackgroundImage.colorMode) {
      try {
        context.getApplicationContext().setColorMode(this.colorMode);
      } catch (error) {
        console.error(`SetColorMode ERROR: ${JSON.stringify(error)}`);
      }
      UnifiedPreferences.putSync('ColorMode', this.colorMode, false);
      BackgroundImage.colorMode = this.colorMode;
      BackgroundImage.syncDarkMode(context);
    }
    // 新背景图：以时间戳命名拷入沙箱（同名路径会命中图片缓存导致不刷新），成功后清理旧文件
    let pickedImgPath: string | undefined = undefined;
    if (this.selectResult !== undefined) {
      try {
        pickedImgPath = BackgroundImage.basicDir + `/backgroundImage_${Date.now()}`;
        await fileIo.copyFile(this.oriImgPath, pickedImgPath);
      } catch (error) {
        pickedImgPath = undefined;
        console.error('Copy image failed:', JSON.stringify(error));
      }
    }
    // 先持久化全部设置，再同步到响应式单例并重算显示状态
    if (pickedImgPath !== undefined) {
      BackgroundImage.cleanBackgroundFiles(pickedImgPath);
      BackgroundImage.imgPath = pickedImgPath;
      if (this.pickedAvgBrightness >= 0)
        BackgroundImage.avgBrightness = this.pickedAvgBrightness;
      UnifiedPreferences.putSync('ImagePath', pickedImgPath, false);
      if (this.pickedAvgBrightness >= 0)
        UnifiedPreferences.putSync('ImageAvgBrightness', this.pickedAvgBrightness, false);
    }
    BackgroundImage.showImage = this.isShown;
    BackgroundImage.backgroundBlur = this.showBlurSlider;
    BackgroundImage.themeColor = this.selectedColor;
    BackgroundImage.autoDecBright = this.autoDecBright;
    UnifiedPreferences.putSync('ShowImage', this.isShown, false);
    UnifiedPreferences.putSync('BackgroundBlur', this.showBlurSlider, false);
    UnifiedPreferences.putSync('BlurLevel', this.blurNum, false);
    UnifiedPreferences.putSync('OpacityLevel', this.opacityNum, false);
    UnifiedPreferences.putSync('ThemeColor', this.selectedColor, false);
    UnifiedPreferences.putSync('BackgroundBrightness', this.imgBrightness, false);
    UnifiedPreferences.putSync('AutoDecBright', this.autoDecBright, false);
    UnifiedPreferences.putSync('AdaptSplit', this.adaptSplit, false);
    UnifiedPreferences.flush();
    BackgroundImage.refreshDisplay();
    // 导航模式热更新：写偏好键adaptSplit（Index的.mode()绑定），实际模式仍由onNavigationModeChange写入isSplit供Webview判断
    AppStorage.setOrCreate('adaptSplit', this.adaptSplit);
    // 不退出 this.pathStack.pop();
  }

  SelectImage() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        if (photoSelectResult.photoUris[0] !== undefined) {
          this.selectResult = photoSelectResult.photoUris[0];
          this.oriImgPath = new fileUri.FileUri(this.selectResult).path;
          this.imageSize = fileIo.statSync(this.oriImgPath).size;
          this.imgPreview = photoSelectResult.photoUris[0];
          this.isShown = true;
          this.pickedAvgBrightness = -1;
          // 提前测量新图片的平均亮度，确认时随图片路径一起持久化
          BackgroundImage.calculateBrightnessByDownSample(this.oriImgPath).then((avg: number) => {
            if (this.selectResult === photoSelectResult.photoUris[0])
              this.pickedAvgBrightness = avg;
          }).catch((err: BusinessError) => {
            console.error(`Calculate image brightness failed: ${JSON.stringify(err)}`);
          });
        }
      }).catch((err: BusinessError) => {
        console.error(`PhotoViewPicker failed: ${JSON.stringify(err)}`)
      })
    } catch (error) {
      console.error(`PhotoViewPicker failed: ${JSON.stringify(error)}`);
    }
  }
}