
export class GridData {
  groupName: ResourceStr = '';
  gridItemList: ResourceStr[] = [];

  constructor(groupName: ResourceStr, gridItemList: ResourceStr[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

export const emptyGridData: GridData = new GridData($r('app.string.ZuiJinShiYong'),
  [
    $r('app.string.empty')
  ]);

// 每个grid所含元素个数&grid总数，添加元素时需要更改
// 不使用.length因为节省时间
export const eachGridNum: number[] = [9, 1, 2];
export const totalGridNum: number = 3

// ListDataConstants.ets也要修改！
export const
  otherGridDataList: GridData[] = [
    new GridData($r('app.string.XueXi'),
      [
        $r('app.string.JiaoWuXiTong'),
        $r('app.string.KeChengBiao'),
        $r('app.string.KaoShiXinXi'),
        $r('app.string.WoDeChengJi'),
        $r('app.string.bbJiaoXuePingTai'),
        $r('app.string.HanHaiJiaoXueWang'),
        $r('app.string.JiaoShiChaXun'),
        $r('app.string.TuShuGuan'),
        $r('app.string.XueXiKongJian')
      ]),
    new GridData($r('app.string.GongJu'),
      [
        $r('app.string.ZhengBanRuanJian')
      ]),
    new GridData($r('app.string.XueXiao'),
      [
        $r('app.string.WangLuoTong'),
        $r('app.string.TongYiShenFenRenZheng')
      ])
  ];
