
import ItemData from '../view/SettingsComponent';

/**
 * Binds data to components and provides interfaces.
 */
export class SettingsData {
  /**
   * Get swiper image data.
   *
   * @return {Array<Resource>} swiperImages.
   */
  getSwiperImages(): Array<Resource> {
    let swiperImages: Resource[] = [
      $r('app.media.default_function_icon'),
      $r('app.media.default_function_icon'),
      $r('app.media.default_function_icon'),
      $r('app.media.default_function_icon')
    ];
    return swiperImages;
  }

  /**
   * Get data of the first grid.
   *
   * @return {Array<PageResource>} firstGridData.
   */
  getFirstGridData(): Array<ItemData> {
    let firstGridData: ItemData[] = [
      new ItemData(0, $r('app.string.page_settings'), $r('app.media.default_function_icon')),
      new ItemData(1, $r('app.string.page_settings'), $r('app.media.default_function_icon')),
      new ItemData(2, $r('app.string.page_function'), $r('app.media.default_function_icon')),
      new ItemData(3, $r('app.string.page_function'), $r('app.media.default_function_icon')),
      new ItemData(4, $r('app.string.page_function'), $r('app.media.default_function_icon')),
      new ItemData(5, $r('app.string.page_settings'), $r('app.media.default_function_icon')),
      new ItemData(6, $r('app.string.page_start'), $r('app.media.default_function_icon')),
      new ItemData(7, $r('app.string.page_settings'), $r('app.media.default_function_icon'))
    ];
    return firstGridData;
  }

  /**
   * Get data of the setting list.
   *
   * @return {Array<PageResource>} settingListData.
   */
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
        new ItemData(3, $r('app.string.remind_before_class'), $r('app.media.calendar_badge_clock')),
        new ItemData(4, $r('app.string.add_class_notification'), $r('app.media.alarm_fill')),
      ],
      [
        new ItemData(5, $r('app.string.about'), $r('app.media.info_circle'))
      ]
    ];
    return settingListData;
  }
}

export default new SettingsData();
