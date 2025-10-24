
/**
 * List item data entity.
 */
export default class PageResource {
  /**
   * ID of list item.
   */
  id: number;
  /**
   * Text of list item.
   */
  title: Resource;
  /**
   * Image of list item.
   */
  img: Resource;
  /**
   * Other resource of list item.
   */
  others?: Resource;

  constructor(id: number, title: Resource, img: Resource, others?: Resource) {
    this.id = id;
    this.title = title;
    this.img = img;
    this.others = others;
  }
}