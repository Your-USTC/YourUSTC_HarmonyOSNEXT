
/**
 * --- 功能页链接表 ---
 * 注意:
 *   ./GridListDataSources.ets
 *   ./Links.ets
 *   ./GridListIcons.ets
 *   ./ListDataConstants.ets
 * 必须同步修改!
 */
import UnifiedPreferences from '../utils/UnifyPreference';

export interface Link {
  title: string | Resource
  url: string | Resource
}

export const LINK = new Map<string, Link>();

if (UnifiedPreferences.getBoolSync('insider', false))
  setInsiderLink();

export function setInsiderLink() {
  LINK
  // 课程与学习
    .set("0.0", { title: $r('app.string.JiaoWuXiTong'), url: 'https://jw.ustc.edu.cn' })
    .set("0.1", { title: $r('app.string.KeChengBiao'), url: 'https://jw.ustc.edu.cn/for-std/course-table' })
    .set("0.2", { title: $r('app.string.KaoShiXinXi'), url: 'https://jw.ustc.edu.cn/for-std/exam-arrange' })
    .set("0.3", { title: $r('app.string.NiDeChengJi'), url: 'https://jw.ustc.edu.cn/for-std/grade/sheet' })
    .set("0.4", { title: $r('app.string.bbJiaoXuePingTai'), url: 'https://www.bb.ustc.edu.cn' })
    .set("0.5", { title: $r('app.string.HanHaiJiaoXueWang'), url: 'http://course.ustc.edu.cn/portal' })
    .set("0.6", { title: $r('app.string.MuKe'), url: 'https://www.icourse163.org/university/USTC#/c' })
    .set("0.7", { title: $r('app.string.GongGongChaXun'), url: 'https://catalog.ustc.edu.cn/query/lesson' })
    .set("0.8", { title: $r('app.string.TuShuGuan'), url: 'https://lib.ustc.edu.cn' })
    .set("0.9", { title: $r('app.string.XueXiKongJian'), url: $rawfile('RoomBookingLinks.html') })
    .set("0.10", { title: $r('app.string.GuoJiJiaoLiu'), url: 'https://vista.ustc.edu.cn' })
    .set("0.11", { title: $r('app.string.DaWuShiYanYuYue'), url: 'https://pems.ustc.edu.cn' })
    .set("0.12", { title: $r('app.string.ZhuJiaoXiTong'), url: 'https://tam.cmet.ustc.edu.cn' })
    .set("0.13", { title: $r('app.string.PingKeSheQu'), url: 'https://icourse.club' })
    .set("0.14", { title: $r('app.string.WolframAlpha'), url: 'https://wolframalpha.com' })
    .set("0.15", { title: $r('app.string.WoKeXueShe'), url: 'https://ot.ustc.edu.cn/' })
    .set("0.16", { title: $r('app.string.KeChengZiLiao'), url: 'https://share.feixu.site' })

    // 服务与工具
    .set("1.0", { title: $r('app.string.ZhiHuiMenHu'), url: 'http://i.ustc.edu.cn' })
    .set("1.1", { title: $r('app.string.QingChunKeDa'), url: 'https://id.ustc.edu.cn/cas/login?service=https:%2F%2Fyoung.ustc.edu.cn%2Flogin%2Fustc-h5-product%2Fpages%2Flogtransit%2Flogtransit' })
    .set("1.2", { title: $r('app.string.QingChunKeDaPC'), url: 'https://young.ustc.edu.cn/login' })
    .set("1.3", { title: $r('app.string.KeDaYouXiang'), url: 'http://mail.ustc.edu.cn' })
    .set("1.4", { title: $r('app.string.KeDaYunPan'), url: 'https://pan.ustc.edu.cn/login?redirect=/home/index' })
    .set("1.5", { title: $r('app.string.WangLuoTong'), url: 'https://zczx.ustc.edu.cn/' })
    .set("1.6", { title: $r('app.string.YiKaTong'), url: 'https://ecard.ustc.edu.cn' })
    .set("1.7", { title: $r('app.string.ZiZhuDaYin'), url: 'https://weixinprinthost.woquyun.com/wq-web/' })
    .set("1.8", { title: $r('app.string.BaoXiuDaTing'), url: 'https://xsfw.ustc.edu.cn' })
    .set("1.9", { title: $r('app.string.XiaoYiYuan'), url: 'https://hospital.ustc.edu.cn/main.htm' })
    .set("1.10", { title: $r('app.string.XueShengYiBao'), url: 'https://xsybxt.ustc.edu.cn' })
    .set("1.11", { title: $r('app.string.Nan7JiShi'), url: 'https://nan7market.com' })
    .set("1.12", { title: $r('app.string.Nan7LunTan'), url: 'https://ustcforum.com' })
    .set("1.13", { title: $r('app.string.YingXinWang'), url: 'http://welcome.ustc.edu.cn' })

    // 信息技术
    .set("2.0", { title: $r('app.string.KeDaVPN'), url: 'https://wvpn.ustc.edu.cn' })
    .set("2.1", { title: $r('app.string.ZhengBanRuanJian'), url: 'https://software.ustc.edu.cn' })
    .set("2.2", { title: $r('app.string.KaiYuanJingXiang'), url: 'https://mirrors.ustc.edu.cn' })
    .set("2.3", { title: $r('app.string.WenDangXieZuo'), url: 'https://latex.ustc.edu.cn' })
    .set("2.4", { title: $r('app.string.SCCGitlab'), url: 'https://git.ustc.edu.cn' })
    .set("2.5", { title: $r('app.string.LUGGitlab'), url: 'https://git.lug.ustc.edu.cn' })
    .set("2.6", { title: $r('app.string.KeDaOJ'), url: 'https://oj.ustc.edu.cn' })
    .set("2.7", { title: $r('app.string.VlabShiYanZhongXin'), url: 'https://vlab.ustc.edu.cn' })
    .set("2.8", { title: $r('app.string.JiYuanKeYanPingTai'), url: 'https://cscourse.ustc.edu.cn' })

    // 学校与管理
    .set("3.0", { title: $r('app.string.TongYiShenFenRenZheng'), url: 'https://id.ustc.edu.cn/gate/cas-success/personal-center-home-page' })
    .set("3.1", { title: $r('app.string.LiFanXiaoDengJi'), url: 'https://lfxdj.ustc.edu.cn' })
    .set("3.2", { title: $r('app.string.QinYouRuXiao'), url: 'https://passport.ustc.edu.cn/login?service=http%3A%2F%2Fbwcqyrx.ustc.edu.cn%2Fweixin%2Fvalidate' })
    .set("3.3", { title: $r('app.string.JiaoWuChu'), url: 'https://teach.ustc.edu.cn' })
    .set("3.4", { title: $r('app.string.YuanXiZhuanYe'), url: 'https://www.teach.ustc.edu.cn/education/239.html' })
    .set("3.5", { title: $r('app.string.LianXiJiaoMi'), url: 'https://www.teach.ustc.edu.cn/service/svc-student/4427.html' })
    .set("3.6", { title: $r('app.string.XueGongYiTiHua'), url: 'https://xgyth.ustc.edu.cn' })
    .set("3.7", { title: $r('app.string.XiaoYuanDiTu'), url: 'https://map.ustc.edu.cn/m' })
    .set("3.8", { title: $r('app.string.QuanJingDiTu'), url: 'https://vr.shouxi360.com/c/vyS6HSJjeej.html' })
    .set("3.9", { title: $r('app.string.XiaoYuanBanChe'), url: 'https://weixine.ustc.edu.cn/ustcqy/mobile/busTimetable_gov' })
    .set("3.10", { title: $r('app.string.YingJuGouPiao'), url: "https://ghticket.ustc.edu.cn" })
}