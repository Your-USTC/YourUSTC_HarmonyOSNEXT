
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import * as ScheduleSources from '../constants/ScheduleSources';
import scheduleManager from '../utils/TimeTable';
import { hilog } from '@kit.PerformanceAnalysisKit';
import UnifiedPreferences, { SCHEDULE_KEY, UID_KEY } from '../utils/UnifyPreference'
import { CardListParameter } from '../class_schedule_daily/viewmodel/CardListParameter';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

class FormDataClass {
  todayCourse: ScheduleSources.classAttribute[] = [];
  tomorrowCourse: ScheduleSources.classAttribute[] = [];
  cardListParameter: CardListParameter = new CardListParameter(
    /* backgroundColor          */ $r('sys.color.ohos_id_color_background'),
    /* title                    */ $r('app.string.schedule_card_title'),
    /* backgroundImage          */ undefined,
    /* backgroundImageSize      */ ImageSize.Auto,
    /* isMask                   */ true,
    /* maskColor                */ $r('app.color.pure_white_or_black'),
    /* isItemCount              */ true,
    /* itemCount                */ 0,
    /* itemCountColor           */ $r('sys.color.ohos_id_color_emphasize'),
    /* itemCountBackgroundColor */ $r('app.color.list_item_count_background'),
    /* titleColor               */ undefined,
    /* isBottomIcon             */ false,
    /* bottomIcon               */ undefined
  )
  lastRefresh: string = '';
  constructor() {
    scheduleManager.getFormattedSchedule();
    if (!scheduleManager.isTermEnd) {
      this.todayCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed][scheduleManager.today];
      this.tomorrowCourse = scheduleManager.formattedSchedule[scheduleManager.weekDisplayed +
        (scheduleManager.today == 5 ? 1 : 0)][(scheduleManager.today + 1) % 7];
    }
    this.cardListParameter.itemCount = this.todayCourse.length;
    const now = scheduleManager.currentTime;
    this.lastRefresh = `上次刷新: ${now.getMonth()}月${now.getDate()}日${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.
    UnifiedPreferences.init(this.context)
    return formBindingData.createFormBindingData(new FormDataClass());
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);

    UnifiedPreferences.init(this.context)
    let formData = new FormDataClass();

    const formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      console.info('FormAbility updateForm success')
    }).catch((error: Error) => {
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
