
import { preferences } from '@kit.ArkData';
import { GridData, emptyGridData } from '../constants/GridListDataSources';
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

export function recordClick(gridIndex: number, index: number, curContext: Context | undefined): void {
  console.log(gridIndex.toString()+'.'+index.toString());
  if (gridIndex == -1) // 常用区 (-1) 不记录
    return;
  let preName: string = gridIndex.toString() + '.' + index.toString(); // 按钮对应首选项名称
  let mostUsedPre: preferences.Preferences | null = null;
  let options: preferences.Options = { name: 'FunctionOrder' };
  mostUsedPre = preferences.getPreferencesSync(curContext, options);
  let latestTime: number = mostUsedPre.getSync(preName, 0) as number; // 读取点击次数

  if (latestTime < 2147483647)
    latestTime++; // 点击次数+1
  mostUsedPre.putSync(preName, latestTime); // 保存新的点击次数
  mostUsedPre.flush(); // 写入最新设置
}


export function refreshFunc(curContext: Context | undefined): void {
  console.log('ok');
  let readPre: preferences.Preferences | null = null;
  let options: preferences.Options = { name: 'FunctionOrder' };
  order = []
  readPre = preferences.getPreferencesSync(curContext, options);
  maxRecord = readPre.getSync('maxRecord', 8) as number;
  let maxCount: number = 0;
  for (let gridIndex = 0;; gridIndex++) {
    let noElement: boolean = true; // 当前 Grid 是否为空
    innerBreak: for (let index = 0;; index++) {
      let preName: string = gridIndex.toString() + '.' + index;
      if (readPre.hasSync(preName)) {
        let preTimes: number = readPre.getSync(preName, 0) as number;
        order.push([preName, preTimes]);
        noElement = false;
        maxCount++;
      }
      else
        break innerBreak;
    }
    if (noElement || maxCount >= maxRecord)
      break;
  }
  order.sort((a, b) => b[1] - a[1]);
  if (order.length == 0)
    setFunc(true);
  else
    setFunc();
}


export function resetFunc(curContext: Context | undefined): void { // 重置"最近使用"
  let options: preferences.Options = { name: 'FunctionOrder' };
  preferences.deletePreferences(curContext, options)
  setFunc(true);
}
