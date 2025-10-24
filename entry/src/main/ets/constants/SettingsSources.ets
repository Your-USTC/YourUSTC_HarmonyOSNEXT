/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import ItemData from '../view/SettingsComponent';

/**
 * Binds data to components and provides interfaces.
 */
export class MainViewModel {
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
        new ItemData(3, $r('app.string.KeChengBiao'), $r('app.media.calendar_badge_clock')),
        new ItemData(4, $r('app.string.page_function'), $r('app.media.default_function_icon')),
      ],
      [
        new ItemData(5, $r('app.string.about'), $r('app.media.default_function_icon'))
      ]
    ];
    return settingListData;
  }
}

export default new MainViewModel();