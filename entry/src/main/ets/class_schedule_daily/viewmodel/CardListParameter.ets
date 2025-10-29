
export class CardListParameter {

  backgroundColor: ResourceColor = '';
  backgroundImage?: ResourceStr;
  backgroundImageSize?: ImageSize;

  isMask?: boolean;
  maskColor?: ResourceColor;

  isItemCount?: boolean;
  itemCount?: number;
  itemCountColor?: ResourceColor;
  itemCountBackgroundColor?: ResourceColor;

  title: ResourceStr = '';
  titleColor?: ResourceColor;

  logo?: ResourceStr;

  isBottomIcon?: boolean;
  bottomIcon?: ResourceStr;

  constructor(
    backgroundColor: ResourceColor,
    title: ResourceStr,
    backgroundImage?: ResourceStr,
    backgroundImageSize?: ImageSize,
    logo?: ResourceStr,
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
    this.logo = logo;
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
