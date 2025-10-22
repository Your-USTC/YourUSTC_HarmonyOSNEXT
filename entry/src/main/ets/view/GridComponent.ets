
import { emptyGridData, GridData } from '../model/GridListDataSources';
import { CommonConstants } from '../constants/CommonConstants';
import { LINK } from '../constants/Links';
import * as FunctionOrder from '../utils/FunctionOrder';
import { gIndex_to_pic } from '../constants/stringForGrid';
import * as tools from '../utils/tools';

@Component
export default struct GridComponent {
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
      }
      .padding({ left: '24vp' })
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Start)

      Grid() {
        ForEach(this.gridData.gridItemList, (item: string, index: number) => { // index: 当前GridComponent的索引
          GridItem() {
            Column() {
              Image(gIndex_to_pic(this.gridIndex, index))
                .width('40vp')
                .height('40vp')
              Text(item)
                .fontSize('12fp')
                .textAlign(TextAlign.Center)
                .margin({ top: '4vp' })
                .height('17vp')
            }
            .height(CommonConstants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
          }
          .height('64vp')
          .onClick(() => {
            if (this.gridIndex == -1) {
              if (FunctionOrder.order.length <= index) {
                this.getUIContext().getPromptAction().showToast({
                  message: $r('app.string.click_empty_gridData' + tools.getRandomInt(1, 7).toString()),
                  // 在 string.ets 里添加时别忘了改 tools.getRandomInt(1, 7)！！
                  duration: 500
                })
              }
              else {
                let preName: string = FunctionOrder.order[index][0];
                if (preName != undefined) {
                  FunctionOrder.recordClick(Number(preName.split('.')[0]), Number(preName.split('.')[1]),
                    this.getUIContext().getHostContext())
                  this.getUIContext().getRouter().pushUrl({
                    url: 'pages/Webview',
                    params: LINK.get(preName)
                  }).catch((err: Error) => {
                    console.error(`Router ERROR: [${err.name}] ${err.message}`)
                  })
                }
              }
            }
            // 跳转 Webview
            else if (LINK.get(this.gridIndex.toString() + '.' + index.toString())?.url.toString() === undefined) { // 未设置对应网址
              this.getUIContext().getPromptAction().showToast({
                message: $r('app.string.WorkingOn'),
                duration: 500
              })
            } else { // 已设置对应网址
              FunctionOrder.recordClick(this.gridIndex, index, this.getUIContext().getHostContext()) // 点击次数+1
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/Webview',
                params: LINK.get(this.gridIndex.toString() + '.' + index.toString())
              }).catch((err: Error) => {
                console.error(`Router ERROR: [${err.name}] ${err.message}`)
              })
            }
          })
        },(item:string,index:number)=>index+JSON.stringify(item))
      }
      .margin({ left: '12vp', right: '12vp', top: '8vp' })
      .borderRadius('12vp')
      .padding('12vp')
      .height(this.getGridHeight())
      .rowsGap('8vp')
      .scrollBar(BarState.Off)
      .columnsTemplate(CommonConstants.GRID_COLUMNS_TEMPLATE)
      .backgroundColor($r('app.color.grid_background'))

      if (this.isLastItem) {
        Blank()
          .height(CommonConstants.FULL_PERCENT)
      }
    }
  }

  getGridHeight(): number {
    //Grid height to be calculated
    let gridHeight: number = 0;
    //Total height of grid items in each row.
    gridHeight += Math.ceil(this.gridData.gridItemList.length / 4) * 68;
    //Total height of the intervals between grid items.
    gridHeight += (Math.ceil(this.gridData.gridItemList.length / 4) - 1) * 8;
    //Top and bottom margins of the grid
    gridHeight += 12 * 2;
    return gridHeight;
  }
}