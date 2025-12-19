
import { GridData } from '../constants/GridListDataSources';
import { LINK } from '../constants/Links';
import * as FunctionOrder from '../utils/FunctionOrder';
import * as tools from '../utils/tools';
import BackgroundImage from '../view/BgImageManager';
import { set_func_num } from './customFuncDialog';

@Component
export default struct GridComponent {
  funcHintController?: CustomDialogController;
  @Prop gridData: GridData = new GridData('', []);
  @State isLastItem: boolean = false;
  @State gridIndex: number = 0;

  build() {
    Column() {
      Row() {
        Text(this.gridData.groupName) // 功能界面各组的标题
          .fontSize('20fp')
          .height('30vp')
          .fontWeight(FontWeight.Bold)
          .margin({ top: '16vp' })
          .padding({ left: 8, right: 8})
          .borderRadius(12)
          .backgroundBlurStyle(BackgroundImage.blurLevel)
          .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.normal_background') : undefined)
      }
      .padding({ left: '16vp' })
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Grid() {
        ForEach(this.gridData.gridItemList, (item: string, index: number) => { // index: 当前GridComponent的索引
          GridItem() {
            Column() {
              Image(FunctionOrder.gIndex_to_pic(this.gridIndex, index))
                .objectFit(ImageFit.Contain)
                .width('40vp')
                .height('40vp')
                .draggable(false)
              Text(item)
                .fontSize('12fp')
                .textAlign(TextAlign.Center)
                .margin({ top: '4vp' })
                .height('17vp')
            }
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .focusable(false)
          .height('64vp')
          .onClick(() => {
            if (this.gridIndex == -1) {
              if (FunctionOrder.order.length <= index) {
                this.getUIContext().getPromptAction().showToast({
                  message: $r('app.string.click_empty_gridData' + tools.getRandomInt(1, 5).toString())
                  // 在 string.ets 里添加时别忘了改 tools.getRandomInt(1, 5)！！
                });
              }
              else {
                let preName: string = FunctionOrder.order[index][0];
                if (preName != undefined) {
                  FunctionOrder.recordClick(Number(preName.split('.')[0]), Number(preName.split('.')[1]));
                  this.getUIContext().getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: LINK.get(preName)
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  });
                }
              }
            }
            // 跳转 Webview
            else if (LINK.get(this.gridIndex.toString() + '.' + index.toString())?.url.toString() === undefined) { // 未设置对应网址
              if (this.funcHintController == undefined) {
                this.getUIContext().getPromptAction().showToast({ message: $r('app.string.under_construction') });
              } else {
                set_func_num(`${this.gridIndex}.${index}`);
                this.funcHintController.open();
              }
            } else { // 已设置对应网址
              FunctionOrder.recordClick(this.gridIndex, index); // 点击次数+1
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/Webview',
                params: LINK.get(this.gridIndex.toString() + '.' + index.toString())
              }).catch((err: Error) => {
                console.error(`Router ERROR: [${err.name}] ${err.message}`)
              });
            }
          })
        },(item:string,index:number)=>index+JSON.stringify(item))
      }
      .margin({ left: '12vp', right: '12vp', top: '8vp' })
      .borderRadius('12vp')
      .padding('12vp')
      .rowsGap('8vp')
      .scrollBar(BarState.Off)
      .columnsTemplate('repeat(auto-fit, 70)')
      .backgroundBlurStyle(BackgroundImage.blurLevel)
      .backgroundColor(BackgroundImage.blurLevel === undefined ? $r('app.color.grid_background') : undefined)

      if (this.isLastItem) {
        Blank()
          .height('100%')
      }
    }
  }
}
