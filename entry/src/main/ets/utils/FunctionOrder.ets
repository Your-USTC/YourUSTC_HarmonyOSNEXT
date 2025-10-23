
import { preferences } from '@kit.ArkData';
import { GridData, emptyGridData, eachGridNum, totalGridNum } from '../constants/GridListDataSources';
import { gIndex_to_name } from '../constants/stringForGrid';

export let mostUsedFunc: GridData = emptyGridData
export let order: Array<[string, number]> = [];
let maxRecord: number = 8;

export function setFunc(toClear: boolean = false): void {
  // toClear: 是否清空，默认为 false
  if (toClear) {
    mostUsedFunc = emptyGridData;
    return;
  }
  mostUsedFunc.gridItemList = [];
  for(let singleFunc of order) {
    let index_to_name = gIndex_to_name.get(singleFunc[0]);
    if (index_to_name === undefined)
      continue;
    mostUsedFunc.gridItemList.push(index_to_name);
  }
}


let mostUsedPre: preferences.Preferences | null = null;
let options: preferences.Options = { name: 'FunctionOrder' };

export function recordClick(gridIndex: number, index: number, curContext: Context | undefined): void {
  if (gridIndex == -1) // 常用区 (-1) 不记录
    return;
  let preName: string = gridIndex.toString() + '.' + index.toString(); // 按钮对应首选项名称
  mostUsedPre = preferences.getPreferencesSync(curContext, options);
  let latestTime: number = mostUsedPre.getSync(preName, 0) as number; // 读取点击次数

  if (latestTime < 2147483647)
    latestTime++; // 点击次数+1
  mostUsedPre.putSync(preName, latestTime); // 保存新的点击次数
  mostUsedPre.flush(); // 写入最新设置
  console.log(gridIndex.toString()+'.'+index.toString() + 'clicked' + latestTime.toString());
}


export function refreshFunc(curContext: Context | undefined): void {
  order = []
  mostUsedPre = preferences.getPreferencesSync(curContext, options);
  maxRecord = mostUsedPre.getSync('maxRecord', 8) as number;
  let maxCount: number = 0;
  for (let gridIndex = 0; gridIndex < totalGridNum; gridIndex++) {
    for (let index = 0; index < eachGridNum[gridIndex]; index++) {
      let preName: string = gridIndex.toString() + '.' + index;
      if (mostUsedPre.hasSync(preName)) {
        let preTimes: number = mostUsedPre.getSync(preName, 0) as number;
        order.push([preName, preTimes]);
        maxCount++;
      }
    }
    if (maxCount >= maxRecord)
      break;
  }
  order.sort((a, b) => b[1] - a[1]);
  if (order.length == 0)
    setFunc(true);
  else
    setFunc();
  console.log('refreshed');
  console.log(order.length.toString());
  for (let test of order)
    console.log(test.toString());
}


export function resetFunc(curContext: Context | undefined): void { // 重置"最近使用"
  preferences.deletePreferences(curContext, options)
  setFunc(true);
}
