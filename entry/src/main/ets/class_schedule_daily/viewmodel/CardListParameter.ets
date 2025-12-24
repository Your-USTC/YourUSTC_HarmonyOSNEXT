
/**
 * 卡片构造参数
 */

export class CardListParameter {

  // 背景
  backgroundColor: ResourceColor = '';
  backgroundImage?: ResourceStr;
  backgroundImageSize?: ImageSize;

  // 底部遮罩
  isMask?: boolean;
  maskColor?: ResourceColor;

  // 计数图标
  isItemCount?: boolean;
  itemCount?: number;
  itemCountColor?: ResourceColor;
  itemCountBackgroundColor?: ResourceColor;

  // 标题
  title: ResourceStr = '';
  titleColor?: ResourceColor;

  // 右下角图标
  isBottomIcon?: boolean;
  bottomIcon?: ResourceStr;

  constructor(
    backgroundColor: ResourceColor,
    title: ResourceStr,
    backgroundImage?: ResourceStr,
    backgroundImageSize?: ImageSize,
    isMask?: boolean,
    maskColor?: ResourceColor,
    isItemCount?: boolean,
    itemCount?: number,
    itemCountColor?: ResourceColor,
    itemCountBackgroundColor?: ResourceColor,
    titleColor?: ResourceColor,
    isBottomIcon?: boolean,
    bottomIcon?: ResourceStr
  ) {
    this.backgroundColor = backgroundColor;
    this.title = title;
    this.backgroundImage = backgroundImage;
    this.backgroundImageSize = backgroundImageSize;
    this.isMask = isMask;
    this.maskColor = maskColor;
    this.isItemCount = isItemCount;
    this.itemCount = itemCount;
    this.itemCountColor = itemCountColor;
    this.itemCountBackgroundColor = itemCountBackgroundColor;
    this.titleColor = titleColor;
    this.isBottomIcon = isBottomIcon;
    this.bottomIcon = bottomIcon;
  }
}
