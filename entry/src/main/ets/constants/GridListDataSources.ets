
/**
 * --- 功能页按钮表 ---
 * 注意:
 *   GridListDataSources.ets
 *   Links.ets
 *   GridListIcons.ets
 *   ListDataConstants.ets
 * 必须同步修改!
 */

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
export const eachGridNum: number[] = [16, 15, 10, 11];
export const totalGridNum: number = 4


export const otherGridDataList: GridData[] = [
  new GridData($r('app.string.XueXi'),
    [
      $r('app.string.JiaoWuXiTong'),
      $r('app.string.KeChengBiao'),
      $r('app.string.KaoShiXinXi'),
      $r('app.string.WoDeChengJi'),
      $r('app.string.bbJiaoXuePingTai'),
      $r('app.string.HanHaiJiaoXueWang'),
      $r('app.string.MuKe'),
      $r('app.string.JiaoShiChaXun'),
      $r('app.string.TuShuGuan'),
      $r('app.string.XueXiKongJian'),
      $r('app.string.GuoJiJiaoLiu'),
      $r('app.string.DaWuShiYanYuYue'),
      $r('app.string.ZhuJiaoXiTong'),
      $r('app.string.PingKeSheQu'),
      $r('app.string.WolframAlpha'),
      $r('app.string.WoKeXueShe')
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
      $r('app.string.QingChunKeDa'),
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
      $r('app.string.QinYouRuXiao'),
      $r('app.string.JiaoWuChu'),
      $r('app.string.YuanXiZhuanYe'),
      $r('app.string.LianXiJiaoMi'),
      $r('app.string.XueGongYiTiHua'),
      $r('app.string.XiaoYuanDiTu'),
      $r('app.string.QuanJingDiTu'),
      $r('app.string.XiaoYuanBaiKe'),
      $r('app.string.XiaoYuanBanChe'),
    ])
];
