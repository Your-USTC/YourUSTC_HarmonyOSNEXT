import { SimpleLink, LinkAddress, MultiLink, LINK } from "../constants/Links";
import { resetWebName } from "../view/MultiPageMenu";
import { gIndex_to_pic, recordClick, refreshFunc } from './FunctionOrder';

function pushNewPage(pageName: string, pageInfo: NavPathStack) {
  if (pageInfo.getAllPathName().includes(pageName)) pageInfo.popToName(pageName);
  else {
    pageInfo.clear();
    pageInfo.pushPath({ name: pageName });
  }
}

function pushNewUrl(title: ResourceStr, url: string | Resource, pageInfo: NavPathStack) {
  pageInfo.clear();
  pageInfo.pushPath({ name: "Webview", param: { title: title, url: url } as SimpleLink})
}

export function pushRedirect(pageInfo: NavPathStack, item: LinkAddress, title?: ResourceStr) {
  if (item.notUrl) {
    pushNewPage(item.url as string, pageInfo);
  } else {
    pushNewUrl(title || 'untitled', item.url, pageInfo);
  }
}


@CustomDialog
export struct linkPickerDialog {
  controller: CustomDialogController;
  @Prop gridIndex: number = 0;
  @Prop index: number = 0;
  pageInfo: NavPathStack = new NavPathStack();
  build() {
    Column() {
      Row({ space: 6 }) {
        Image(gIndex_to_pic(this.gridIndex, this.index))
          .height(36)
          .width(36)
          .objectFit(ImageFit.Contain)

        Text(LINK[this.gridIndex].set[this.index].title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Button({ buttonStyle: ButtonStyleMode.NORMAL, type: ButtonType.Circle }) {
          Image($r('app.media.close'))
            .height(20)
            .width(20)
        }
        .width(36)
        .height(36)
        .onClick(() => {
          this.controller.close();
        })
      }
      .width('100%')

      ForEach(LINK[this.gridIndex].set[this.index].url, (item: LinkAddress, index: number) => {
        Row({ space: 5 }) {
          Text((index + 1).toString())
            .width(30)
            .fontSize(18)
            .textAlign(TextAlign.Center)
            .fontWeight(FontWeight.Bold)
          Text(item.subtitle)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .padding({ right: 30 })
        .width('100%')
        .height(40)
        .onClick(() => {
          pushRedirect(this.pageInfo, item, LINK[this.gridIndex].set[this.index].title as string);
          this.controller.close();
        })

        Divider()
      })

      Text('󰊗 此处仅提供快捷入口，开发者不对其内容负责，不保证其有效性')
        .fontSize(10)
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
    }
    .padding(16)
    .width('100%')
  }
}