
export interface Link {
  title: string | Resource
  url: string | Resource
}

export let LINK = new Map<string, Link>()
  .set("0.0", { title: $r('app.string.JiaoWuXiTong'), url: 'https://jw.ustc.edu.cn' })
  .set("0.1", { title: $r('app.string.KeChengBiao'), url: 'https://jw.ustc.edu.cn/for-std/course-table'})
  .set("0.2", { title: $r('app.string.KaoShiXinXi'), url: 'https://jw.ustc.edu.cn/for-std/exam-arrange'})
  .set("0.3", { title: $r('app.string.WoDeChengJi'), url: 'https://jw.ustc.edu.cn/for-std/grade/sheet'})
  .set("0.8", { title: $r('app.string.XueXiKongJian'), url: $rawfile('RoomBookingLinks.html')})