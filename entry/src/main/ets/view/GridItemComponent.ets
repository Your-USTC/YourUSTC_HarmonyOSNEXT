
import { CommonConstants } from '../constants/CommonConstants';

@Component
export default struct GridItemComponent {
  itemName: string = '';
  itemImage: Resource = $r('app.media.default_function_icon');

  build() {

    GridItem() {
      Column() {
        Image(this.itemImage)
          .width('40vp')
          .height('40vp')
          .onClick(() => {
            this.getUIContext().getPromptAction().showToast({
              message: '敬请期待',
              duration: 500
            })
          })
        Text(this.itemName)
          .fontSize('12fp')
          .textAlign(TextAlign.Center)
          .margin({ top: '4vp' })
          .height('17vp')
      }
      .height(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
    }
    .height('64vp')
  }
}