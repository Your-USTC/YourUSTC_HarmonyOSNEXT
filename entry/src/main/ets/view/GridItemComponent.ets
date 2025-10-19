
import { CommonConstants } from '../constants/CommonConstants';
import { preferences } from '@kit.ArkData'
import { featureGridData } from '../model/GridListDataSources';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export default struct GridItemComponent {
  itemName: string = '';
  itemImage: Resource = $r('app.media.default_function_icon');
  private pref: preferences.Preferences | null = null; // 保存点击次数

  build() {

    GridItem() {
      Column() {
        Image(this.itemImage)
          .width('40vp')
          .height('40vp')
        Text(this.itemName)
          .fontSize('12fp')
          .textAlign(TextAlign.Center)
          .margin({ top: '4vp' })
          .height('17vp')
      }
      .height(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.getUIContext().getPromptAction().showToast({
          message: '敬请期待',
          duration: 500
        })

        let options: preferences.Options = { name: 'function_order' };
        this.pref = preferences.getPreferencesSync(getContext(this), options);
        let clickTimes: number = this.pref.getSync(String(this.itemName), 0) as number; // this.itemName为什么是object类型？？
        hilog.debug(0x0010, '当前itemName类型', '%{public}s', typeof this.itemName); //debug需删
        clickTimes += 1;
        this.pref.putSync(String(this.itemName), clickTimes); // this.itemName为什么是object类型？？
        this.pref.flush();
        hilog.debug(0x0010, "clicked times", String(clickTimes)); // debug需删
      })
    }
    .height('64vp')
  }
}


// 不知道什么用

export class ClickTracker {
  static clickMap: Map<string, number> = new Map();

  static recordClick(item: ResourceStr) {
    const key = item.toString();
    ClickTracker.clickMap.set(key, (ClickTracker.clickMap.get(key) || 0) + 1);
    ClickTracker.updateFeatureData();
    console.log("record!"+item[0])
  }

  private static updateFeatureData() {
    const sorted = Array.from(ClickTracker.clickMap.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8)
      .map(item => item[0] as ResourceStr);

    featureGridData.gridItemList = sorted.length > 0 ? sorted : [$r('app.string.empty')];
  }
}