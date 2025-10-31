
import { classAttribute } from './Schedule';
import * as tools from '../utils/tools';

@Entry
@Component
struct CourseEdit {
  @State classInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2', weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 1 };

  onPageShow(): void {
    console.log('edit page');
  }

  @Builder
  MyMenu(){
    Menu(){
      MenuItem( { content: "test1" })
      MenuItem( { content: "test2" })
    }
  }

  build() {
    Column() {
      // 触发菜单的组件（如右上角图标）
      Image($r('app.media.right_arrow'))
        .width(40)
        .height(40)
        .margin({ top: 10, right: 10 })
        // 绑定菜单（长按/右键触发）
        .bindMenu(this.MyMenu())
    }
  }
}