
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

  readStoredExam() {
    let data = UnifiedPreferences.getSync('examInfo', '');
    if (data === '')
      this.allExamInfo = [];
    else
      this.allExamInfo = JSON.parse(data);
  }

  storeExam(data: string) {
    if (data !== '')
      UnifiedPreferences.putSync('examInfo', data);
  }
}

export default new examManager();