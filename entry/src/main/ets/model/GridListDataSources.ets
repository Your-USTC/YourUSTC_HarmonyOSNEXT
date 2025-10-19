
export class GridData {
  groupName: ResourceStr = '';
  gridItemList: ResourceStr[] = [];

  constructor(groupName: ResourceStr, gridItemList: ResourceStr[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

export const featureGridData: GridData = new GridData($r('app.string.sub_title1'),
  [
    $r('app.string.sub_title1_value1'),
    $r('app.string.sub_title1_value2'),
    $r('app.string.sub_title1_value3'),
    $r('app.string.sub_title1_value4'),
    $r('app.string.sub_title1_value5'),
    $r('app.string.sub_title1_value6'),
    $r('app.string.sub_title1_value7')
  ]);

export const
  otherGridDataList: GridData[] = [
    new GridData($r('app.string.sub_title2'),
      [
        $r('app.string.sub_title2_value1'),
        $r('app.string.sub_title2_value2'),
        $r('app.string.sub_title2_value3'),
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
    new GridData($r('app.string.sub_title3'),
      [
        $r('app.string.sub_title3_value1'),
        $r('app.string.sub_title3_value2'),
        $r('app.string.sub_title3_value3')
      ]),
    new GridData($r('app.string.sub_title4'),
      [
        $r('app.string.sub_title4_value1'),
        $r('app.string.sub_title4_value2'),
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


