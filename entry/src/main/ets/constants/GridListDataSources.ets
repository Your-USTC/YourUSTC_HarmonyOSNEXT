
export class GridData {
  groupName: ResourceStr = '';
  gridItemList: ResourceStr[] = [];

  constructor(groupName: ResourceStr, gridItemList: ResourceStr[]) {
    this.groupName = groupName;
    this.gridItemList = gridItemList;
  }
}

// 每个grid所含元素个数&grid总数，添加元素时需要更改
// 不使用.length因为节省时间
export const eachGridNum: number[] = [15, 14, 10, 2];
export const totalGridNum: number = 4

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
        $r('app.string.XueXiKongJian'),
        $r('app.string.GuoJiJiaoLiu'),
        $r('app.string.DaWuShiYanYuYue'),
        $r('app.string.ZhuJiaoXiTong'),
        $r('app.string.PingKeSheQu'),
        $r('app.string.WolframAlpha'),
        $r('app.string.QingChunKeDa'),
      ]),
    new GridData($r('app.string.GongJu'),
      [
        $r('app.string.YingXinWang'),
        $r('app.string.KeDaYouXiang'),
        $r('app.string.ZiZhuDaYin'),
        $r('app.string.Nan7JiShi'),
        $r('app.string.Nan7LunTan'),
        $r('app.string.WangLuoTong'),
        $r('app.string.YiKaTong'),
        $r('app.string.XiaoYiYuan'),
        $r('app.string.XueShengYiBao'),
        $r('app.string.ZhuSuFuWu'),
        $r('app.string.KeDaWangPan'),
        $r('app.string.USTCDaoHang'),
        $r('app.string.ZhiHuiMenHu'),
        $r('app.string.WangLuoZhuCeZhongXin'),
      ]),
    new GridData($r('app.string.XinXiJiShu'),
      [
        $r('app.string.KeDaVPN'),
        $r('app.string.WangLuoQiDong'),
        $r('app.string.ZhengBanRuanJian'),
        $r('app.string.KaiYuanJingXiang'),
        $r('app.string.LUGGitlab'),
        $r('app.string.ChaoSuanZhongXinGitlab'),
        $r('app.string.KeDaOJ'),
        $r('app.string.VLABShiYanZhongXin'),
        $r('app.string.JiYuanKeYanPingTai'),
        $r('app.string.WenDangXieZuo'),
      ]
    ),
    new GridData($r('app.string.XueXiao'),
      [
        $r('app.string.TongYiShenFenRenZheng'),
        $r('app.string.LiFanXiaoDengJi'),
      ])
  ];
