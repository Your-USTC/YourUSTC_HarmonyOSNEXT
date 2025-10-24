
export default class PageResource {
  id: number;
  title: Resource;
  img: Resource;
  others?: Resource;

  constructor(id: number, title: Resource, img: Resource, others?: Resource) {
    this.id = id;
    this.title = title;
    this.img = img;
    this.others = others;
  }
}
