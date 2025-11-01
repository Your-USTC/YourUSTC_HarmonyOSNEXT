
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

  // 服务与工具
  .set('1.0', $r('app.media.ZhiHuiMenHu'))              // 智慧门户
  .set('1.1', $r('app.media.QingChunKeDa'))             // 青春科大
  .set('1.2', $r('app.media.KeDaYouXiang'))             // 科大邮箱
  .set('1.3', $r('app.media.KeDaYunPan'))               // 科大云盘
  .set('1.4', $r('app.media.WangLuoTong'))              // 网络通
  .set('1.5', $r('app.media.YiKaTong'))                 // 一卡通
  .set('1.6', $r('app.media.ZiZhuDaYin'))               // 自助打印
  .set('1.7', $r('app.media.BaoXiuDaTing'))             // 报修大厅
  .set('1.8', $r('app.media.XiaoYiYuan'))               // 校医院
  .set('1.9', $r('app.media.XueShengYiBao'))            // 学生医保
  .set('1.10', $r('app.media.Nan7JiShi'))               // 南七集市 (有深浅图标)
  .set('1.11', $r('app.media.Nan7LunTan'))              // 南七论坛
  .set('1.12', $r('app.media.YingXinWang'))             // 迎新网
  .set('1.13', $r('app.media.USTCDaoHang'))             // USTC导航

  // 信息技术
