import { preferences } from '@kit.ArkData';
import { GridData } from '../model/GridListDataSources';
import { gIndex_to_name } from '../constants/grid_index_to_name';

export let mostUsedFunc: GridData = new GridData($r('app.string.ZuiJinShiYong'), [$r('app.string.empty')])

export function setFunc(order: Array<[string, number]>): void {
  mostUsedFunc.gridItemList = []
  for(let singleFunc of order) {
    mostUsedFunc.gridItemList.push(gIndex_to_name.get(singleFunc[0]) as ResourceStr);
  }
}

export function recordClick(gridIndex: number, index: number, curContext: Context | undefined): void {
  let preName: string = gridIndex.toString() + '.' + index.toString(); // 按钮对应首选项名称
  let mostUsedPre: preferences.Preferences | null = null;
  let options: preferences.Options = { name: 'FunctionOrder' };
  mostUsedPre = preferences.getPreferencesSync(curContext, options);
  let latestTime: number = mostUsedPre.getSync(preName, 0) as number; // 读取点击次数

  if (latestTime < 2147483647)
    latestTime++; // 点击次数+1
  mostUsedPre.putSync(preName, latestTime); // 保存新的点击次数
  mostUsedPre.flush() // 写入最新设置
}


export function refreshFunc(curContext: Context | undefined): void {
  let readPre: preferences.Preferences | null = null;
  let order: Array<[string, number]> = [];
  for (let gridIndex = 0;; gridIndex++) {
    let noElement: boolean = true // 当前 Grid 是否为空
    innerBreak: for (let index = 0;; index++) {
      let preName: string = gridIndex.toString() + '.' + index;
      let options: preferences.Options = { name: 'FunctionOrder' };
      readPre = preferences.getPreferencesSync(curContext, options);
      let preTime: number = readPre.getSync(preName, -1) as number;
      if (preTime == -1)
        break innerBreak;
      noElement = true
      order.push([preName, preTime]);
    }
    if (noElement)
      break;
  }
  order.sort((a, b) => b[1] - a[1]);
  for (let single of order) {
    console.log(single.toString())
  }
}


export function resetFunc(curContext: Context | undefined): void {
  let options: preferences.Options = { name: 'FunctionOrder' };
  preferences.deletePreferences(curContext, options)
}