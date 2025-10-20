
export class GridData {
  groupName: ResourceStr = '';
  gridItemList: ResourceStr[] = [];

  constructor(groupName: ResourceStr, gridItemList: ResourceStr[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

export const featureGridData: GridData = new GridData($r('app.string.ZuiJinShiYong'),
  [
    $r('app.string.empty')
  ]);

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
        $r('app.string.ZhengBanRuanJian'),
        // $r('app.string.sub_title2_value3'),
        $r('app.string.sub_title2_value4'),
        $r('app.string.sub_title2_value5'),
        $r('app.string.sub_title2_value6'),
        $r('app.string.sub_title2_value7'),
        $r('app.string.sub_title2_value8'),
        $r('app.string.sub_title2_value9'),
        $r('app.string.sub_title2_value10'),
        $r('app.string.sub_title2_value11'),
        $r('app.string.sub_title2_value12'),
        $r('app.string.sub_title2_value13'),
        $r('app.string.sub_title2_value14')
      ]),
    new GridData($r('app.string.XueXiao'),
      [
        $r('app.string.WangLuoTong'),
        $r('app.string.TongYiShenFenRenZheng'),
        $r('app.string.sub_title4_value3'),
        $r('app.string.sub_title4_value4'),
        $r('app.string.sub_title4_value5'),
        $r('app.string.sub_title4_value6')
      ]),
    new GridData($r('app.string.sub_title5'),
      [
        $r('app.string.sub_title5_value1'),
        $r('app.string.sub_title5_value2'),
        $r('app.string.sub_title5_value3'),
        $r('app.string.sub_title5_value4'),
        $r('app.string.sub_title5_value5'),
        $r('app.string.sub_title5_value6')]),
    new GridData($r('app.string.sub_title6'), [
      $r('app.string.sub_title6_value1'),
      $r('app.string.sub_title6_value2'),
      $r('app.string.sub_title6_value3'),
      $r('app.string.sub_title6_value4'),
      $r('app.string.sub_title6_value5'),
      $r('app.string.sub_title6_value6'),
      $r('app.string.sub_title6_value7'),
      $r('app.string.sub_title6_value8')]),
  ];


