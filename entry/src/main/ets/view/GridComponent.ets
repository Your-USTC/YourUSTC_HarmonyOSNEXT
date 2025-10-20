
import { GridData } from '../model/GridListDataSources';
import { CommonConstants } from '../constants/CommonConstants';

@Component
export default struct GridComponent {
  @State gridData: GridData = new GridData('', []);
  @State isLastItem: boolean = false;

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
        ForEach(this.gridData.gridItemList, (item: string) => {
          GridItem() {
            Column() {
              Image($r('app.media.default_function_icon')) // 待转换成 item - 图片 索引
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
            this.getUIContext().getPromptAction().showToast({
              message: '敬请期待',
              duration: 500
            })
            // 获取 index
            console.log(item.toString()) // ???
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