import { AddFormMenuItem } from "@kit.ArkUI";
import { formBindingData } from "@kit.FormKit";
import { BusinessError, deviceInfo } from "@kit.BasicServicesKit";
import BackgroundImage, { presetColor } from  '../utils/BgImageManager';


@Builder
export function AddCardBuilder() {
  if (deviceInfo.deviceType === 'phone')
    AddCard({ cardSize: { maxWidth: 300, maxHeight: 140 } });
  else if (deviceInfo.deviceType === 'tablet')
    AddCard({ cardSize: { maxWidth: 360, maxHeight: 160 } });
  else
    AddCard({ cardSize: { maxWidth: 412, maxHeight: 180 } });
}

@Entry
@Component
struct AddCard {
  cardSize: ConstraintSizeOptions | undefined;

  @Builder CardMenu(cardType: number, bindComponent: string) {
    Menu() {
      AddFormMenuItem({
        bundleName: 'com.nic.dailynic',
        abilityName: 'EntryFormAbility',
        parameters: {
          'ohos.extra.param.key.form_dimension': 3, // 卡片尺寸，1代表1*2卡片，2代表2*2卡片，3代表2*4卡片，4代表4*4卡片，7代表6*4卡片
          'ohos.extra.param.key.form_name': cardType === 0 ? 'class_schedule_daily' : 'exam_info',
          'ohos.extra.param.key.module_name': 'entry'
        }
      },
      bindComponent, {
        formBindingData: formBindingData.createFormBindingData(cardType),
        callback: (error: BusinessError, _formId) => {
          // 会触发onAddForm的回调，因此无需UnifyPreference.putSync
          if (error.code === 0)
            this.getUIContext().getPromptAction().showToast({ message: '已添加到桌面' });
          else
            this.getUIContext().getPromptAction().showToast({ message: '添加失败，原因：' + error.message });
        }
      })
    }
  }

  @Builder SimulateCard(title: ResourceStr, hint: ResourceStr, hintImage: ResourceStr) {
    Column({ space: FlexAlign.Start }) {
      Row() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .height(20)
          .padding({ right: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('0')
          .textAlign(TextAlign.Center)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_emphasize'))
          .backgroundColor($r('app.color.list_item_count_background'))
          .width(24)
          .height(16)
          .borderRadius(8)

        Text('点击右侧按钮刷新')
          .opacity(0.8)
          .fontSize(12)
          .margin({ right: 4 })
          .textAlign(TextAlign.End)
          .layoutWeight(1)

        Image($r('app.media.refresh'))
          .width(20)
          .height(20)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ bottom: 2 })

      List() {
        ListItem() {
          Column() {
            Image(hintImage)
              .height(60)
            Text(hint)
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height('100%')
        .padding({ top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .alignListItem(ListItemAlign.Center)
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
  }

  pathStack: NavPathStack = new NavPathStack();
  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Text('点击下面的卡片以添加 2×4 大小的卡片到桌面；此外，长按桌面上的 App 图标，可以添加 4×4 大小的卡片。')
            .padding({ left: 8, right: 8 })

          Row({ space: 5 }) {
            Image($r('app.media.class_card'))
              .height(30);
            Text('课程卡片')
              .fontSize(20)
              .fontWeight(FontWeight.Bold);
            Divider()
              .layoutWeight(1);
          }
          .margin({ top: 16, bottom: 5 })
          .width('100%')

          Text('每天 00:00 自动刷新一次。由于系统限制，若设备处于锁屏状态，则解锁后刷新，或者小概率不刷新。')
            .margin({ bottom: 3 })
            .padding({ left: 8, right: 8 })

          Column() {
            this.SimulateCard($r('app.string.schedule_card_title'), $r('app.string.no_class_today'), $r('app.media.no_course_today'))
          }
          .padding({ top: 12, left: 12, right: 12 })
          .width('100%')
          .height('100%')
          .constraintSize(this.cardSize)
          .borderRadius(20)
          .backgroundColor($r('app.color.grid_background'))
          .id('ClassCard')
          .bindMenu(this.CardMenu(0, 'ClassCard'))

          Row({ space: 5 }) {
            Image($r('app.media.exam_card'))
              .height(30);
            Text('考试卡片')
              .fontSize(20)
              .fontWeight(FontWeight.Bold);
            Divider()
              .layoutWeight(1);
          }
          .margin({ top: 16, bottom: 5 })
          .width('100%')

          Text('大约每 3 小时自动刷新一次。由于系统限制，若设备处于锁屏状态，则解锁后刷新，或者小概率不刷新。')
            .margin({ bottom: 3 })
            .padding({ left: 8 , right: 8 })

          Column() {
            this.SimulateCard($r('app.string.exam_info_display_name'), $r('app.string.no_exam_info1'), $r('app.media.no_exam1'))
          }
          .padding({ top: 12, left: 12, right: 12 })
          .width('100%')
          .height('100%')
          .constraintSize(this.cardSize)
          .borderRadius(20)
          .backgroundColor($r('app.color.grid_background'))
            .id('ExamCard')
            .bindMenu(this.CardMenu(1, 'ExamCard'))

          Row({ space: 5 }) {
            Image($r('app.media.exam_card'))
              .fillColor(presetColor[BackgroundImage.themeColor][2])
              .height(30);
            Text('快捷方式')
              .fontSize(20)
              .fontWeight(FontWeight.Bold);
            Divider()
              .layoutWeight(1);
          }
          .margin({ top: 16, bottom: 5 })
          .width('100%')

          Text('你也可以按照下图所示步骤，在桌面添加课表和考试的快捷方式，点击快捷方式即可直达相应页面。')
            .margin({ bottom: 3 })
            .padding({ left: 8, right: 8 })

          Image($r('app.media.shortcut'))
            .width('100%')
            .height('100%')
            .constraintSize({ maxWidth: '218px', maxHeight: '346px' })
            .objectFit(ImageFit.Contain)
            .borderRadius(10)
        }
        .width('100%')
        .padding(8)
        .backgroundColor(BackgroundImage.showImage && BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
        .backgroundBlurStyle(BackgroundImage.blurLevel)
        .borderRadius(23)
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .padding(9)
    }
    .title($r('app.string.add_desktop_form'), {
      backgroundBlurStyle: BackgroundImage.blurLevel,
      backgroundColor: (BackgroundImage.blurLevel === undefined ? $r('app.color.shaded_background' + String(BackgroundImage.themeColor)) : '#0000')
    })
    .backButtonIcon($r('app.media.close'))
    .backgroundColor(BackgroundImage.showImage ? '#0000' : $r('app.color.normal_background'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}