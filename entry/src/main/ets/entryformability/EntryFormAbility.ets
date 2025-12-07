
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import * as ScheduleSources from '../constants/ScheduleSources';
import scheduleManager from '../utils/TimeTable';
import { hilog } from '@kit.PerformanceAnalysisKit';
import UnifiedPreferences, { SCHEDULE_KEY, UID_KEY } from '../utils/UnifyPreference'

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.

    const formData = '';
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
  }

  /*onFormEvent(formId: string, message: string) {
    // Called when a specified message event defined by the form provider is triggered.
    const currentTime = new Date();
    class FormDataClass {
      todayCourse: ScheduleSources.classAttribute[] = [];
      isTodayCourseEnd: boolean = true;
      tomorrowCourse: ScheduleSources.classAttribute[] = [];
    }
    let formData = new FormDataClass();
    scheduleManager.getFormattedSchedule(); // 初始化首页课表
    if (scheduleManager.isTermEnd) {
      formData.todayCourse = [];
      formData.tomorrowCourse = [];
    } else {
      formData.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
      formData.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
    }
    formData.isTodayCourseEnd = true;
    for (let todaySingleCourse of formData.todayCourse)
      if (currentTime.getTime() < scheduleManager.weekStart + (scheduleManager.today + 1) % 7 * 86400000
        + ScheduleSources.commonClassStamp[todaySingleCourse.timeSpan[todaySingleCourse.timeSpan.length - 1]][1]) {
        formData.isTodayCourseEnd = false;
        break;
      }
    console.log(`卡片：${JSON.stringify(formData.todayCourse)}`)
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formInfo).then(() => {}).catch((error: BusinessError) => {});
  }*/

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);
    UnifiedPreferences.init(this.context)
    class FormDataClass {
      detail: string = '';
      todayCourse: ScheduleSources.classAttribute[] = [];
      tomorrowCourse: ScheduleSources.classAttribute[] = [];
      constructor() {
        /*if (scheduleManager.isTermEnd) {
          formData.todayCourse = [];
        } else {
          formData.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
        }*/
        scheduleManager.getFormattedSchedule();
        this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
        this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed + (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
        this.detail = `${formId}`;
      }
    }

    let formData = new FormDataClass();

    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      console.info('FormAbility updateForm success')
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}
