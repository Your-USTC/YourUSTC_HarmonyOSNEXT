/* eslint-disable no-unused-vars */
function getUrlParams(url) {
  // 通过 ? 分割获取后面的参数字符串
  let urlStr = url.split('?')[1];
  if (!urlStr) {
    return {};
  }
  // 创建空对象存储参数
  let obj = {};
  // 再通过 & 将每一个参数单独分割出来
  let paramsArr = urlStr.split('&');
  for (let i = 0, len = paramsArr.length; i < len; i++) {
    // 再通过 = 将每一个参数分割为 key:value 的形式
    let arr = paramsArr[i].split('=');
    obj[arr[0]] = arr[1];
  }
  return obj;
}
function htmlEncode(str) {
  if (!str) {
    return '';
  }
  let s = '';
  s = str.replace(/&/g, '&amp;');
  s = s.replace(/</g, '&lt;');
  s = s.replace(/>/g, '&gt;');
  s = s.replace(/ /g, '&nbsp;');
  s = s.replace(/'/g, '&#39;');
  s = s.replace(/"/g, '&quot;');
  return s;
}
function checkUrl(value) {
  // 网站地址
  const REG_URL = /^(http|https):\/\/([\w.]+\/?)\S*/;

  // 网站地址不包含@
  const REG_URL_WITHOUT_AT = /^(https:\/\/|http:\/\/)[^@]*$/;
  return !REG_URL.test(value) || !REG_URL_WITHOUT_AT.test(value);
}
