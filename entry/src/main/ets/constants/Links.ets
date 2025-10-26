
export interface Link {
  title: string | Resource
  url: string | Resource
}

export let LINK = new Map<string, Link>()
  .set("0.0", { title: $r('app.string.JiaoWuXiTong'), url: 'https://jw.ustc.edu.cn' })
  .set("0.1", { title: $r('app.string.KeChengBiao'), url: 'https://jw.ustc.edu.cn/for-std/course-table'})
  .set("0.2", { title: $r('app.string.KaoShiXinXi'), url: 'https://jw.ustc.edu.cn/for-std/exam-arrange'})
  .set("0.3", { title: $r('app.string.WoDeChengJi'), url: 'https://jw.ustc.edu.cn/for-std/grade/sheet'})
  .set("0.4", { title: $r('app.string.bbJiaoXuePingTai'), url: 'https://www.bb.ustc.edu.cn'})
  .set("0.5", { title: $r('app.string.HanHaiJiaoXueWang'), url: 'http://course.ustc.edu.cn/portal'})
  .set("0.6", { title: $r('app.string.JiaoShiChaXun'), url: 'https://catalog.ustc.edu.cn/query/lesson'})
  .set("0.7", { title: $r('app.string.TuShuGuan'), url: 'https://lib.ustc.edu.cn'})
  .set("0.8", { title: $r('app.string.XueXiKongJian'), url: $rawfile('RoomBookingLinks.html')})
  .set("0.9", { title: $r('app.string.GuoJiJiaoLiu'), url: 'https://vista.ustc.edu.cn'})
  .set("0.10", { title: $r('app.string.DaWuShiYanYuYue'), url: 'https://pems.ustc.edu.cn'})
  .set("0.11", { title: $r('app.string.ZhuJiaoXiTong'), url: 'https://tam.cmet.ustc.edu.cn'})
  .set("0.12", { title: $r('app.string.PingKeSheQu'), url: 'https://icourse.club'})
  .set("0.13", { title: $r('app.string.WolframAlpha'), url: 'https://wolframalpha.com'})
  .set("0.14", { title: $r('app.string.QingChunKeDa'), url: 'https://young.ustc.edu.cn/login/sc-wisdom-group-learning/myproject/SignUp'})
  .set("1.0", { title: $r('app.string.YingXinWang'), url: 'http://welcome.ustc.edu.cn'})
  .set("1.1", { title: $r('app.string.KeDaYouXiang'), url: 'http://mail.ustc.edu.cn'})
  .set("1.2", { title: $r('app.string.ZiZhuDaYin'), url: 'http://ic.lib.ustc.edu.cn'})
  .set("1.3", { title: $r('app.string.Nan7JiShi'), url: 'https://nan7market.com'})
  .set("1.4", { title: $r('app.string.Nan7LunTan'), url: 'https://ustcforum.com'})
  .set("1.5", { title: $r('app.string.WangLuoTong'), url: 'http://wlt.ustc.edu.cn'})
  .set("1.6", { title: $r('app.string.YiKaTong'), url: 'https://ecard.ustc.edu.cn'})
  .set("1.7", { title: $r('app.string.XiaoYiYuan'), url: 'https://hospital.ustc.edu.cn/main.htm'})
  .set("1.8", { title: $r('app.string.XueShengYiBao'), url: 'https://xsybxt.ustc.edu.cn'})
  .set("1.9", { title: $r('app.string.ZhuSuFuWu'), url: 'https://zhusu.ustc.edu.cn'})
  .set("1.10", { title: $r('app.string.KeDaWangPan'), url: 'https://pan.ustc.edu.cn'})
  .set("1.11", { title: $r('app.string.USTCDaoHang'), url: 'https://ustc.life'})
  .set("1.12", { title: $r('app.string.ZhiHuiMenHu'), url: 'http://i.ustc.edu.cn'})
  .set("1.13", { title: $r('app.string.WangLuoZhuCeZhongXin'), url: 'https://zczx.ustc.edu.cn'})
  .set("2.0", { title: $r('app.string.KeDaVPN'), url: 'https://wvpn.ustc.edu.cn'})
  .set("2.1", { title: $r('app.string.WangLuoQiDong'), url: 'https://pxe.ustc.edu.cn'})
  .set("2.2", { title: $r('app.string.ZhengBanRuanJian'), url: 'https://software.ustc.edu.cn'})
  .set("2.3", { title: $r('app.string.KaiYuanJingXiang'), url: 'https://mirrors.ustc.edu.cn'})
  .set("2.4", { title: $r('app.string.LUGGitlab'), url: 'https://git.lug.ustc.edu.cn'})
  .set("2.5", { title: $r('app.string.ChaoSuanZhongXinGitlab'), url: 'https://git.ustc.edu.cn'})
  .set("2.6", { title: $r('app.string.KeDaOJ'), url: 'https://oj.ustc.edu.cn'})
  .set("2.7", { title: $r('app.string.VLABShiYanZhongXin'), url: 'https://vlab.ustc.edu.cn'})
  .set("2.8", { title: $r('app.string.JiYuanKeYanPingTai'), url: 'https://cscourse.ustc.edu.cn'})
  .set("2.9", { title: $r('app.string.WenDangXieZuo'), url: 'https://latex.ustc.edu.cn'})
  .set("3.0", { title: $r('app.string.TongYiShenFenRenZheng'), url: 'https://passport.ustc.edu.cn'})
  .set("3.1", { title: $r('app.string.LiFanXiaoDengJi'), url: 'https://lfxdj.ustc.edu.cn'})


/*
    收集的链接:
    {
      "name": "EducationalAdministrationCenter_url",
      "value": "https://teach.ustc.edu.cn"
    },
    {
      "name": "AdmissionsOffice_url",
      "value": "https://zsb.ustc.edu.cn"
    },
    {
      "name": "WokeStudyingSociety_url",
      "value": "https://ot.ustc.edu.cn"
    },
    {
      "name": "AdmissionRain_url",
      "value": "https://adrain.ustclug.org"
    },
    {
      "name": "SecretaryInformation_url",
      "value": "https://www.teach.ustc.edu.cn/service/svc-student/4427.html"
    },
    {
      "name": "FacultyAndMajorSummary_url",
      "value": "https://www.teach.ustc.edu.cn/education/239.html"
    },
    {
      "name": "TeachingCalendar_url",
      "value": "https://www.teach.ustc.edu.cn/calendar/19081.html"
    },
    {
      "name": "RelativesAndFriendsAppointment_url",
      "value": "https://passport.ustc.edu.cn/login?service=http%3A%2F%2Fbwcqyrx.ustc.edu.cn%2Fweixin%2Fvalidate"
    },
    {
      "name": "CampusMap_url",
      "value": "https://map.ustc.edu.cn"
    },
    {
      "name": "CampusPanorama_url",
      "value": "https://vr.shouxi360.com/c/pNiHHxiHjPg.html"
    },
    {
      "name": "SchoolBusQuery_url",
      "value": "https://weixine.ustc.edu.cn/ustcqy/mobile/busTimetable_gov"
    },
    {
      "name": "PersonalCenter_url",
      "value": "https://id.ustc.edu.cn"
    }
*/