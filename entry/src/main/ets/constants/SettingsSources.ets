
import ItemData from '../view/SettingsComponent';

export class SettingsData {
  getSettingListData(): Array<Array<ItemData>> {
    let settingListData: ItemData[][] = [
      [
        new ItemData(0, $r('app.string.page_start'), $r('app.media.default_function_icon'), $r("app.string.setting_toggle"))
      ],
      [
        new ItemData(1, $r('app.string.setMaxRecord'), $r('app.media.more')),
        new ItemData(2, $r('app.string.ClearFunctionHistory'), $r('app.media.clean')),
      ],
      [
        new ItemData(3, $r('app.string.clear_calendar'), $r('app.media.xmark_circle')),
        new ItemData(4, $r('app.string.add_class_notification'), $r('app.media.calendar_badge_clock')),
      ],
      [
        new ItemData(5, $r('app.string.help'), $r('app.media.questionmark_circle')),
        new ItemData(6, $r('app.string.about'), $r('app.media.info_circle'))
      ]
    ];
    return settingListData;
  }
}

export default new SettingsData();
