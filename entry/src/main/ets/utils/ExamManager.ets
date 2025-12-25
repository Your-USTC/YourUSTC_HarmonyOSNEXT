
/**
 * 考试信息管理
 */

import UnifiedPreferences from './UnifyPreference';

// 考试信息结构体
export interface examAttribute {
  id: string,
  type: string,
  name: string,
  date: string,
  classroom: string,
  building: string,
  campus: string,
  info: string,
  beginTimeStamp: number,
  endTimeStamp: number,
  importance: number
}

export function areExamAttributesEqual(a: examAttribute, b: examAttribute): boolean {
  // 基本类型直接比较
  if (a.id !== b.id) return false;
  if (a.type !== b.type) return false;
  if (a.name !== b.name) return false;
  if (a.date !== b.date) return false;
  if (a.classroom !== b.classroom) return false;
  if (a.building !== b.building) return false;
  if (a.campus !== b.campus) return false;
  if (a.info !== b.info) return false;
  if (a.importance !== b.importance) return false;
  // 所有字段都相同
  return true;
}

class examManager {

  allExamInfo: examAttribute[] = [];

  // 读取
  readStoredExam() {
    let data = UnifiedPreferences.getSync('examInfo', '');
    if (data === '')
      this.allExamInfo = [];
    else
      this.allExamInfo = JSON.parse(data);
  }

  // 存储
  storeExam(data: examAttribute[]) {
    for (let i = 0; i < data.length; i++) {
      data[i].beginTimeStamp = new Date(data[i].date.slice(0, 16)).getTime();
      data[i].endTimeStamp = new Date(data[i].date.slice(0, 11) + data[i].date.slice(17, 22)).getTime();
      if (data[i].importance == undefined)
        data[i].importance = 5;
    }
    data.sort((a, b) => {
      if (a.importance !== b.importance) {
        return b.importance - a.importance;
      }
      return a.beginTimeStamp - b.beginTimeStamp;
    });
    UnifiedPreferences.putSync('examInfo', JSON.stringify(data));
  }

  // 添加
  addExam(newExam: examAttribute) {
    newExam.beginTimeStamp = new Date(newExam.date.slice(0, 16)).getTime();
    newExam.endTimeStamp = new Date(newExam.date.slice(0, 11) + newExam.date.slice(17, 22)).getTime();
    this.allExamInfo.push(newExam);
    this.allExamInfo.sort((a, b) => {
      if (a.importance !== b.importance) {
        return b.importance - a.importance;
      }
      return a.beginTimeStamp - b.beginTimeStamp;
    });
    UnifiedPreferences.putSync('examInfo', JSON.stringify(this.allExamInfo));
  }

  // 删除
  deleteExam(deletedExam: examAttribute) {
    for (let i = this.allExamInfo.length - 1; i >= 0; i--)
      if (areExamAttributesEqual(deletedExam, this.allExamInfo[i])) {
        this.allExamInfo.splice(i, 1);
        break;
      }
    this.storeExam(this.allExamInfo);
  }
}

export default new examManager();
