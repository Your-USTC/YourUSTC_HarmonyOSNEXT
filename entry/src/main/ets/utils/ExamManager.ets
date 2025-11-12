
import UnifiedPreferences from './UnifyPreference';

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
  endTimeStamp: number
}

function areExamAttributesEqual(a: examAttribute, b: examAttribute): boolean {
  // 基本类型直接比较
  if (a.id !== b.id) return false;
  if (a.type !== b.type) return false;
  if (a.name !== b.name) return false;
  if (a.date !== b.date) return false;
  if (a.classroom !== b.classroom) return false;
  if (a.building !== b.building) return false;
  if (a.campus !== b.campus) return false;
  if (a.info !== b.info) return false;
  // 所有字段都相同
  return true;
}

class examManager {
  allExamInfo: examAttribute[] = [];

  readStoredExam() {
    let data = UnifiedPreferences.getSync('examInfo', '');
    if (data === '')
      this.allExamInfo = [];
    else
      this.allExamInfo = JSON.parse(data);
  }

  storeExam(data: examAttribute[]) {
    for (let i = 0; i < data.length; i++){
      data[i].beginTimeStamp = new Date(data[i].date.slice(0, 16)).getTime();
      data[i].endTimeStamp = new Date(data[i].date.slice(0, 11) + data[i].date.slice(17, 22)).getTime();
    }
    data.sort((a, b) => a.beginTimeStamp - b.beginTimeStamp);
    UnifiedPreferences.putSync('examInfo', JSON.stringify(data));
  }

  addExam(newExam: examAttribute) {
    newExam.beginTimeStamp = new Date(newExam.date.slice(0, 16)).getTime();
    newExam.endTimeStamp = new Date(newExam.date.slice(0, 11) + newExam.date.slice(17, 22)).getTime();
    console.log('aaa',newExam.date.slice(0, 11) + newExam.date.slice(17, 22));
    this.allExamInfo.push(newExam);
    this.allExamInfo.sort((a, b) => a.beginTimeStamp - b.beginTimeStamp);
    UnifiedPreferences.putSync('examInfo', JSON.stringify(this.allExamInfo));
  }

  deleteExam(deletedExam: examAttribute) {
    for (let i = 0; i < this.allExamInfo.length; i++)
      if (areExamAttributesEqual(deletedExam, this.allExamInfo[i])) {
        this.allExamInfo.splice(i, 1);
        break;
      }
    this.storeExam(this.allExamInfo);
  }
}

export default new examManager();