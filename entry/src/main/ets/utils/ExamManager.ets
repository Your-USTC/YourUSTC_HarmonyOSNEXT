
import UnifiedPreferences from './UnifyPreference';

export interface examAttribute {
  id: string,
  type: string,
  name: string,
  date: string,
  classroom: string,
  building: string,
  campus: string,
  info: string
}

class examManager {
  allExamInfo: examAttribute[] = [];

  readStoredExam(data: string = '') {
    if (data === '')
      data=UnifiedPreferences.getSync('examInfo', '');
    if (data === '')
      this.allExamInfo = [];
    else
      this.allExamInfo = JSON.parse(data);
  }

  refreshStoredExam(data: string) {
    UnifiedPreferences.putSync('examInfo', data);
    this.readStoredExam(data);
  }
}

export default new examManager();