
import { CounterComponent, CounterType } from '@kit.ArkUI';
import { customizeClick, gIndex_to_pic, getClickCount } from '../utils/FunctionOrder';
import { LINK, MultiLink } from '../constants/Links';
import { refreshFunc, mostUsedFunc } from '../utils/FunctionOrder';
import { presetColor } from '../utils/BgImageManager';
import BackgroundImage from '../utils/BgImageManager';

@CustomDialog
export default struct CustomClick {
  dialogController: CustomDialogController;
  gridIndex: number = 0;
  index: number = 0;
  clickTimes: number = 0;
  @Link copyMostUsedFunc: MultiLink[];

  build() {
    Column() {
      Row({ space: 5 }) {
        Image(gIndex_to_pic(this.gridIndex, this.index))
          .height(30)
          .width(30)

        Text(LINK[this.gridIndex].set[this.index].title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .layoutWeight(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        CounterComponent({
          options: {
            type: CounterType.INLINE,
            inlineOptions: {
              value: getClickCount(this.gridIndex, this.index),
              min: 0, step: 1, max: 2147483647,
              onChange: (value: number) => { this.clickTimes = value; }
            }
          }
        })
      }
      .width('97%')
      .margin({ bottom: 5 })

      Text($r('app.string.custom_click_into_s', LINK[this.gridIndex].set[this.index].title))
        .width('90%')
        .wordBreak(WordBreak.BREAK_ALL)

      Row() {
        Button($r('app.string.cancel'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .width('50%')
          .onClick(() => this.dialogController.close())
          .fontColor(presetColor[BackgroundImage.themeColor].accentColor)

        Button($r('app.string.ok'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .width('50%')
          .backgroundColor(presetColor[BackgroundImage.themeColor].accentColor)
          .onClick(() => {
            customizeClick(this.gridIndex, this.index, this.clickTimes);
            refreshFunc(); // 刷新点击次数显示
            this.copyMostUsedFunc = mostUsedFunc;
            this.dialogController.close();
          })
      }
      .margin({ top: 5 })
    }
    .width('100%')
    .padding(16)
  }
}