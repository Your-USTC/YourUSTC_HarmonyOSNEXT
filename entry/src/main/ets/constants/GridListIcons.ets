
/**
 * --- 功能页图标表 ---
 * 注意:
 *   GridListDataSources.ets
 *   Links.ets
 *   GridListIcons.ets
 *   ListDataConstants.ets
 * 必须同步修改!
 */

export let index_to_pic = new Map<string, ResourceStr>()
  // 课程与学习
  .set('0.0', $r('app.media.JiaoWuXiTong'))             // 教务系统
  .set('0.1', $r('app.media.KeChengBiao'))              // 课程表
  .set('0.2', $r('app.media.KaoShiXinXi'))              // 考试信息
  .set('0.3', $r('app.media.WoDeChengJi'))              // 我的成绩
  .set('0.4', $r('app.media.bbJiaoXuePingTai'))         // Bb教学平台
  .set('0.5', $r('app.media.HanHaiJiaoXueWang'))        // 瀚海教学网
  .set('0.6', $r('app.media.MuKe'))                     // 慕课
  .set('0.7', $r('app.media.GongGongChaXun'))           // 公共查询
  .set('0.8', $r('app.media.TuShuGuan'))                // 图书馆
  .set('0.9', $r('app.media.XueXiKongJian'))            // 学习空间
  .set('0.10', $r('app.media.GuoJiJiaoLiu'))            // 国际交流
  .set('0.11', $r('app.media.DaWuShiYanYuYue'))         // 大物实验预约
  .set('0.12', $r('app.media.ZhuJiaoXiTong'))           // 助教系统
  .set('0.13', $r('app.media.PingKeSheQu'))             // 评课社区
  .set('0.14', $r('app.media.WolframAlpha'))            // Wolfram Alpha
  .set('0.15', $r('app.media.WoKeXueShe'))              // 蜗壳学社
  .set('0.16', $r('app.media.KeChengZiLiao'))           // 课程资料

  // 服务与工具
  .set('1.0', $r('app.media.ZhiHuiMenHu'))              // 智慧门户
  .set('1.1', $r('app.media.QingChunKeDa'))             // 青春科大
  .set('1.2', $r('app.media.QingChunKeDa'))             // 青春科大
  .set('1.3', $r('app.media.KeDaYouXiang'))             // 科大邮箱
  .set('1.4', $r('app.media.KeDaYunPan'))               // 科大云盘
  .set('1.5', $r('app.media.WangLuoTong'))              // 网络通
  .set('1.6', $r('app.media.YiKaTong'))                 // 一卡通
  .set('1.7', $r('app.media.ZiZhuDaYin'))               // 自助打印
  .set('1.8', $r('app.media.BaoXiuDaTing'))             // 报修大厅
  .set('1.9', $r('app.media.XiaoYiYuan'))               // 校医院
  .set('1.10', $r('app.media.XueShengYiBao'))            // 学生医保
  .set('1.11', $r('app.media.Nan7JiShi'))               // 南七集市 (有深浅图标)
  .set('1.12', $r('app.media.Nan7LunTan'))              // 南七茶馆
  .set('1.13', $r('app.media.YingXinWang'))             // 迎新网

  // 信息技术
  .set('2.0', $r('app.media.KeDaVPN'))                  // Web VPN
  .set('2.1', $r('app.media.ZhengBanRuanJian'))         // 正版软件
  .set('2.2', $r('app.media.KaiYuanJingXiang'))         // 开源镜像
  .set('2.3', $r('app.media.WenDangXieZuo'))            // 文档协作
  .set('2.4', $r('app.media.SCCGitLab'))                // SCC GitLab
  .set('2.5', $r('app.media.LUGGitLab'))                // LUG GitLab
  .set('2.6', $r('app.media.KeDaOJ'))                   // 科大 OJ
  .set('2.7', $r('app.media.VlabShiYanZhongXin'))       // Vlab 实验中心
  .set('2.8', $r('app.media.JiYuanKeYanPingTai'))       // 计院科研平台

  // 学校与管理
  .set('3.0', $r('app.media.TongYiShenFenRenZheng'))    // 统一身份认证
  .set('3.1', $r('app.media.LiFanXiaoDengJi'))          // 离返校登记
  .set('3.2', $r('app.media.QinYouRuXiao'))             // 亲友入校
  .set('3.3', $r('app.media.JiaoWuChu'))                // 教务处
  .set('3.4', $r('app.media.YuanXiZhuanYe'))            // 院系专业
  .set('3.5', $r('app.media.LianXiJiaoMi'))             // 联系教秘
  .set('3.6', $r('app.media.XueGongYiTiHua'))           // 学工一体化
  .set('3.7', $r('app.media.XiaoYuanDiTu'))             // 校园地图
  .set('3.8', $r('app.media.QuanJingDiTu'))             // 全景地图
  .set('3.9', $r('app.media.XiaoYuanBanChe'))           // 校园班车
  .set('3.10', $r('app.media.YingJuGouPiao'))           // 影剧购票
