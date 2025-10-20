import { preferences } from '@kit.ArkData';
import { GridData } from '../model/GridListDataSources';

export class FunctionOrder {
  mostUsedGrid: GridData = new GridData($r('app.string.ZuiJinShiYong'), [$r('app.string.KeChengBiao')])

  static recordClick(pref: preferences.Preferences, item: ResourceStr): number {
    if (pref != null) {

    }
    console.log(item[0] + "保存失败！" + item[1])
    return -1;
  }
}