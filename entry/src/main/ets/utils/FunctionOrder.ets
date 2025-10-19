import { preferences } from '@kit.ArkData';

export class FunctionOrder {
  static recordClick(pref: preferences.Preferences, item: ResourceStr): number {
    if (pref != null) {

    }
    console.log(item[0] + "保存失败！" + item[1])
    return -1;
  }
}