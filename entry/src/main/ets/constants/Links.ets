
export interface Link {
  title: string | Resource
  url: string | Resource
}

export let LINK = new Map<string, Link>();
LINK.set("0.0", { title: $r('app.string.JiaoWuXiTong'), url: 'https://jw.ustc.edu.cn' });
LINK.set("0.1", { title: $r('app.string.KeChengBiao'), url: 'https://jw.ustc.edu.cn/for-std/course-table'})
LINK.set("0.2", { title: $r('app.string.KaoShiXinXi'), url: 'https://jw.ustc.edu.cn/for-std/exam-arrange'})
LINK.set("0.3", { title: $r('app.string.WoDeChengJi'), url: 'https://jw.ustc.edu.cn//for-std/grade/sheet'})