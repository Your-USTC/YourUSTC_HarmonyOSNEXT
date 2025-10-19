
/**
 * Common constants for all features.
 */
export class CommonConstants {
  /**
   * Table grid nested list uri.
   */
  static readonly TABLE_GRID_NEST_LIST_URI: string = 'pages/GridNestListIndex';

  /**
   * Table grid nested swiper uri.
   */
  static readonly TABLE_GRID_NEST_SWIPER_URI: string = 'pages/GridNestSwiperIndex';

  /**
  * Table grid nested list uri.
  */
  static readonly WATER_FLOW_LAYOUT_WEIGHT: number = 1;

  /**
  * Divider stroke width
  */
  static readonly DIVIDER_STROKE_WIDTH: number = 2;

  /**
  * List space size
  */
  static readonly LIST_SPACE_SIZE: number = 16;

  /**
  * Height of the first page of the swiper
  */
  static readonly SWIPER_HEIGHT_SIZE1: number = 175;

  /**
   * Height of the second page of the swiper.
   */
  static readonly SWIPER_HEIGHT_SIZE2: number = 100;

  /**
   * The height of the WaterFlow item
   */
  static readonly WATER_FLOW_GROUP_BOTTOM_MARGIN: number = 12;

  /**
   * The height of the WaterFlow item
   */
  static readonly WATER_FLOW_ITEM_HEIGHT: number = 159;

  /**
   * The Animation Duration of swiper
   */
  static readonly SWIPER_DURATION: number = 700;

  /**
   * The ninety percent of the components
   */
  static readonly NINETY_PERCENT: string = '90%';

  /**
   * The height of list
   */
  static readonly LIST_HEIGHT: string = 'calc(100% - 40vp)';

  /**
   * The hundred  percent of the components
   */
  static readonly FULL_PERCENT: string = '100%';

  /**
   * Water flow layout columns template
   */
  static readonly GRID_COLUMNS_TEMPLATE: string = '1fr 1fr 1fr 1fr';

}

/**
 * The state of main page
 */
export enum ScrollPosition {
  start = 0,
  center = 1,
  end = 2
}