
import * as FunctionOrder from '../utils/FunctionOrder'

export let gIndex_to_name = new Map<string, ResourceStr>()
  .set('0.0', $r('app.string.JiaoWuXiTong'))
  .set('0.1', $r('app.string.KeChengBiao'))
  .set('0.2', $r('app.string.KaoShiXinXi'))
  .set('0.3', $r('app.string.WoDeChengJi'))
  .set('0.4', $r('app.string.bbJiaoXuePingTai'))
  .set('0.5', $r('app.string.HanHaiJiaoXueWang'))
  .set('0.6', $r('app.string.JiaoShiChaXun'))
  .set('0.7', $r('app.string.TuShuGuan'))
  .set('0.8', $r('app.string.XueXiKongJian'))

let index_to_pic = new Map<string, ResourceStr>()
  .set('0.0', $r('app.media.tab0_selected')) // 占位符
  .set('0.1', $r('app.media.tab0_unselected'))

export function gIndex_to_pic(gridIndex: number, index: number): ResourceStr {
  if (gridIndex == -1){
    if (FunctionOrder.order.length <= index)
      return $r('app.media.default_function_icon');
    let preName: string = FunctionOrder.order[index][0];
    gridIndex = Number(preName.split('.')[0]);
    index = Number(preName.split('.')[1]);
  }
  let result = index_to_pic.get(gridIndex.toString() + '.' + index.toString());
  if (result == undefined)
    return $r('app.media.default_function_icon');
  else
    return result;
}
