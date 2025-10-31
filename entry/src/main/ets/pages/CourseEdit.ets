
import { classAttribute } from './Schedule';
import * as tools from '../utils/tools';

@Entry
@Component
struct CourseEdit {
  @State classInfo: classAttribute = { name: '计算机程序设计', teacher: '李卫海', location: '3A212', id: 'CS1003.H2', weekOfTerm: tools.getContArray([[2, 10], [13, 16]]) as number[], timeSpan: [6, 7], dayOfWeek: 1 };

  build() {
    Column() {
      Text('edit')
    }
  }
}