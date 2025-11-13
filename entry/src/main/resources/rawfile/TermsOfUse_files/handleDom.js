/* eslint-disable guard-for-in */
/* eslint-disable no-undef */

window.onload = init;
function init() {
  // templateType:(1：元服务，2：应用)，type:(1：用户隐私政策，2：用户协议)
  const { templateType, type, layoutType } = agreementInfo;
  const isMetaService = templateType !== 2;
  const query = getUrlParams(window.location.href);

  const lang = handleLang(query, agreementInfo);
  const isRtlDirection = lang === 'ug';
  setHtmlDirection(isRtlDirection);
  window.agreementInfos = agreementInfo.agreementInfos.find(item => item.lang === lang);

  initDarkBgColor(query);
  initI18n(lang);
  handleDomI18n();
  let isNewTemplate = layoutType === 2;
  setNewOrOldDomVisible(isNewTemplate);
  let baseInfo = agreementInfos.baseInfo;
  document.title = `${baseInfo.appName}`;
  document.getElementById('privacyName').innerText = i18n.t('amp.agreement.previewTitle', {
    appName: baseInfo.appName,
  });
  handleTotalTitle(baseInfo, isMetaService, isNewTemplate);
  handleVersionAndSummary(isMetaService, isNewTemplate);
  let diff = 0;
  handleCollectPersonInfo(isNewTemplate, isMetaService);
  if(agreementInfos.devicePermissions?.length) {
    diff++;
    handleDevicePermissions(lang, isNewTemplate);
  }
  let childPrivacyUrl = agreementInfos.extInfo.childPrivacyUrl;
  if (childPrivacyUrl) {
    diff++;
    handleMinorsInfo(diff, isNewTemplate);
  }
  if (agreementInfos.thirdSharedInfos?.length) {
    diff++;
    handleThirdSharedInfo(diff, lang, isNewTemplate);
  }
  if (agreementInfos.thirdSdkInfo?.sdkInfos?.length) {
    diff++;
    handleThirdSdkInfo(diff, lang, isNewTemplate);
  }
  if(isNewTemplate) {
    handlePersonInfo(diff, isMetaService);
  } else {
    handleOldPersonInfo(diff, isMetaService)
  }
  handleStorage(diff, isNewTemplate);
  diff = handleCustomData(diff, isNewTemplate, agreementInfos);

  handleContactInfo(diff, isMetaService);
  handleTime(isRtlDirection);
  document.getElementsByTagName('body')[0].style.display = 'block';
}

function htmlEncode(html) {
  if (!html) {
    return '';
  }
  const temp = document.createElement("span");
  temp.innerText = html;
  const output = temp.innerHTML;
  return output;
}


function parseRGBA(value) {
  let val = value.trim().toLowerCase();
  let color = {};
  try {
    let argb = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(val);
    color.r = parseInt(argb[2], 16);
    color.g = parseInt(argb[3], 16);
    color.b = parseInt(argb[4], 16);
    color.a = parseInt(argb[1], 16) / 255;
  } catch (e) {
    color = {
      r: 0,
      g: 0,
      b: 0,
      a: 1,
    }
  }
  return 'rgba(' + color.r + ',' + color.g + ',' + color.b + ',' + color.a.toFixed(1) + ')';
}

function initDarkBgColor(query) {
  let color = 'rgba(0, 0, 0, 1.0)';
  if (query.darkModeBgColor) {
    color = parseRGBA(query.darkModeBgColor);
  }
  const styleDom = document.getElementById('style');
  styleDom.innerHTML = `
    @media (prefers-color-scheme: dark) {
      body {
        background-color: ${color};
      }
    }
  `;
}


function handleCustomData(diff, isNewTemplate, agreementInfos) {
  let index = diff;
  if (isNewTemplate) {
    const customDataLength = agreementInfos.extInfo.customInfo?.customInfos?.length;
    if (customDataLength) {
      handleCustomInfo(index);
      index += customDataLength;
    }
  } else {
    if (agreementInfos.extInfo.customInfo && JSON.stringify(agreementInfos.extInfo.customInfo) !== '{}') {
      index++;
      handleOldCustomInfo(index);
    }
  }
  return index;
}

function setNewOrOldDomVisible(isNew) {
  if (isNew) {
    document.getElementById('permissions-title').style.display = "none";
    document.getElementById('permissions-foot').style.display = "none";
  } else {
    document.getElementById('app-subtitle').style.display = "none";
  }
}

function handleLang(query, agreementInfo) {
  // 旧客户端，不走新的语言处理
  if (Number(query.ver ?? '') < 2) {
    return query.lang;
  }
  // 14.3版本及以后，走新的语言处理
  let lang = getLangByParams(query.lang);
  if (!agreementInfo.agreementInfos.find(item => item.lang === lang)) {
    return agreementInfo.defaultLang || 'zh';
  }
  return lang;
}

function setHtmlDirection(isRtlDirection) {
  if(isRtlDirection) {
    document.documentElement.setAttribute('dir', 'rtl');
  }
}

function getLangByParams(lang) {
  if (lang.startsWith('ug')) {
    return 'ug';
  }
  if (lang.startsWith('bo')) {
    return 'bo';
  }
  if(['zh-Hant-HK', 'zh-Hant-MO', 'zh-HK', 'zh-MO'].includes(lang)) {
    return 'zh-Hant-HK';
  }
  if(['zh-CN', 'zh-SG'].includes(lang) || lang.startsWith('zh-Hans')) {
    return 'zh';
  }
  if(lang === 'zh-TW' || lang.startsWith('zh')) {
    return 'zh-Hant-TW';
  }
  return 'en';
}

function handleUseReasonText(requiredInfo) {
  let str = '';
  let classMap = { 0: 'normal', 1: 'bold', undefined: 'normal' };
  for (let i = 0; i < requiredInfo.length; i++) {
    const item = requiredInfo[i];
    let spanStr = '';
    for (let j = 0; j < item.dataItems.length; j++) {
      spanStr +=
        `<span class=${classMap[item.dataItems[j].sensitiveData]}>${
          item.dataItems[j].itemDesc
        }${j < item.dataItems.length - 1 ? '、' : ''}</span> `;
    }
    let isSensitive = item.dataItems.some((item) => item.sensitiveData);
    const COLLECT_MODE_EMPTY_ID = '1202';
    let i18nKey = 'amp.agreement.collectAndDo';
    let collectMode = item.collectMode;
    if (item.collectModeId === COLLECT_MODE_EMPTY_ID) {
      i18nKey = 'amp.agreement.collectWithoutMode';
      collectMode = '';
    }
    str += `<p>${
      i18n.t(i18nKey, {
        thing: `<span class=${classMap[Number(isSensitive)]}>${item.sceneReason}</span>`,
        lawBasis: item.legalBasis,
        collectMode,
        permission: spanStr,
      })
    }</p><p>${htmlEncode(item.remark) || ''}</p>`;
  }
  return str;
}

function handleRequire(requiredInfo) {
  let reqUl = document.getElementById('required-ul');
  let reqTitle = document.getElementById('required-title');
  if (!requiredInfo.length) {
    reqTitle.style.display = 'none';
  }
  reqUl.innerHTML += handleUseReasonText(requiredInfo);
}

function handleRecommend(sceneItems, closeSetting, index) {
  if (!closeSetting) {
    return false;
  }
  let recommendDom = document.getElementById('recommend-info');
  let str = `<p id="recommend-title">1.${index} ${i18n.t('amp.agreement.previewRecommendInfoTitle')}</p><p>${i18n.t('amp.agreement.personalRecommendInfoDesc')}</p><ul id="recommend-ul"></ul>`;
  recommendDom.innerHTML = str;
  let recUl = document.getElementById('recommend-ul');
  let liStr = '';
  const classMap = { 0: 'normal', 1: 'bold', undefined: 'normal' };
  for (let i = 0; i < sceneItems.length; i++) {
    let itemDescArr = [];
    let isSensitive = false;
    for (let j = 0; j < sceneItems[i].dataItems.length; j++) {
      const { sensitiveData, itemDesc } = sceneItems[i].dataItems[j];
      itemDescArr.push(`<span class="${classMap[sensitiveData]}">${itemDesc}</span>`);
      if (sensitiveData) {
        isSensitive = true;
      }
    }
    liStr += `<p>${i18n.t('amp.agreement.collectAndrecommend', {
      permission: itemDescArr.join('、'),
      service: `<span class="${isSensitive ? 'bold' : 'normal'}">${sceneItems[i].sceneReason}</span>`,
    })}</p>`;
  }
  liStr += `<p>${i18n.t('amp.agreement.closePath', {
    path: htmlEncode(closeSetting),
  })}</p>`;
  recUl.innerHTML = liStr;
}

function handleAds(adsInfo, index) {
  const { sceneItems, pushContent, closeSetting } = adsInfo;
  let adsDom = document.getElementById('ads-info');
  let str = '';
  let itemDesc = [];
  for (let j = 0; j < sceneItems[0].dataItems.length; j++) {
    const item = sceneItems[0].dataItems[j];
    itemDesc.push(`<span class="${item.sensitiveData === 1 ? 'bold' : ''}">${item.itemDesc}</span>`);
  }
  str = `<p id="ads-title">1.${index}${i18n.t('amp.agreement.previewAdsInfoFirstTitle')}</p>
    <p>${i18n.t('amp.agreement.push', { content: htmlEncode(pushContent) })}${i18n.t('amp.agreement.usePermissionAndClose', { permission: itemDesc.join('、'), path: htmlEncode(closeSetting) })}</p>`;
  adsDom.innerHTML = str;
}

function handleFullService(fullServiceMode, appName, index, isNewTemplate) {
  const { selectPath, personalCollectType, basicServiceType, extraServiceType } = fullServiceMode;
  const collectTypeMap = {
    '1': i18n.t('amp.agreement.notCollectPersonalInfo'),
    '2': i18n.t(isNewTemplate ? 'amp.agreement.collectPersonalInfo' : 'amp.agreement.collectPersonalInfoOld'),
  };
  const reqUl = document.getElementById('full-service');
  reqUl.innerHTML = `<p>1.${index} ${i18n.t(isNewTemplate ? 'amp.agreement.useInfoService' : 'amp.agreement.useInfoServiceOld', {
      appName: htmlEncode(appName),
      path: htmlEncode(selectPath),
      collectMode: collectTypeMap[personalCollectType],
      ability: htmlEncode(basicServiceType),
      unAbility: htmlEncode(extraServiceType),
    })}
  </p>`;
}

function handleContract(contractObligationMode, index) {
  const { serviceTypeInfos, serviceType, personalCollectReason } = contractObligationMode;
  const list = [];
  const reasonMap = {
    '1': i18n.t('amp.agreement.collectReasonSign'),
    '2': i18n.t('amp.agreement.collectReasonFulfill'),
  };
  serviceTypeInfos.forEach(item => {
    list.push(...item.sceneItems);
  });
  const reqUl = document.getElementById('contract');
  reqUl.innerHTML = `
    <p>1.${index} ${i18n.t('amp.agreement.useInfoContract', { ability: htmlEncode(serviceType), do: reasonMap[personalCollectReason] })}</p>
    ${handleUseReasonText(list)}
  `;
}

function handleLaw(lawRegulationMode, index) {
  const list = [];
  lawRegulationMode.serviceTypeInfos.forEach(item => {
    list.push(...item.sceneItems);
  });
  const reqUl = document.getElementById('law');
  reqUl.innerHTML = `<p>1.${index} ${i18n.t('amp.agreement.dealInfoReason')}</p>${handleUseReasonText(list)}`;
}

function handleDevicePermissions(lang, isNewTemplate) {
  document.getElementById('device-permissions').style.display = 'block';
  let devicePermissions = agreementInfos.devicePermissions || [];
  let pUl = document.getElementById('permissions-ul');
  let str = '';
  for (let i = 0; i < devicePermissions.length; i++) {
    if (isNewTemplate) {
      const permission = devicePermissions[i];
      const label = permission.permissions.map((val) => val.permissionDesc).join(lang === 'zh' ? '、' : ',');
      const lableName = lang === 'zh' ? `（${label}）` : `(${label})`;
      str += `
        <p>${permission.groupName}${lableName}</p>
        <p>${htmlEncode(permission.reason)}</p>
      `
    } else {
      let itemDesc = [];
      for (let j = 0; j < devicePermissions[i].permissions.length; j++) {
        itemDesc.push(devicePermissions[i].permissions[j].permissionDesc);
      }
      str += `<p>${i18n.t('amp.agreement.useDeviceAndDo', { permission: itemDesc.join('、'), do: htmlEncode(devicePermissions[i].reason) })}</p>`;
    }
  }
  pUl.innerHTML += str;
}

function handleMinorsInfo(diff, isNewTemplate) {
  const index = diff + 1;
  document.getElementById('child-policy-title').innerText = `${index}. ${i18n.t('amp.agreement.childInfo')}`;
  document.getElementById('child-policy-second').innerText = `${index}.1 ${i18n.t('amp.agreement.childInfoFirstDescNew')}`;
  let { childPrivacyUrl, extFieldCustomInfo }= agreementInfos.extInfo;
  let protectDom = document.getElementById('protect-minors');
  let str = '';
  if(isNewTemplate) {
    str = `<p>
      ${index}.2 ${i18n.t('amp.agreement.childPrivacy', { url: `<a href='${childPrivacyUrl}'>《${htmlEncode(extFieldCustomInfo?.childPrivacyTitle)}》</a>` })}</p>
      <p>${htmlEncode(extFieldCustomInfo?.childPrivacyCustomInfoDesc) || ''}</p>`
  } else {
    str = `<p>
    ${index}.2 ${i18n.t('amp.agreement.childPrivacy', { url: `<a href='${childPrivacyUrl}'>《${i18n.t('amp.agreement.childInfoTips')}》</a>` })}</p>`;
  }
  protectDom.innerHTML = str;
}

function handleThirdSharedInfo(diff, lang, isNewTemplate) {
  let thirdSharedInfos = agreementInfos.thirdSharedInfos;
  let thirdSharedDom = document.getElementById('third-shared');
  let str = `<h5 class="shared-title"> ${1 + diff}. ${i18n.t('amp.agreement.toastThirdSharedInfo')}</h5>
  <div class="shared-info">
    <p class="shared-content">
      ${i18n.t('amp.agreement.thirdShareInfoDesc')}
    </p>
    ${thirdSharedInfos.map(({ name, serviceType, personalType, purpose, scene, shareType, officialPrivacyUrl, dataItems = [] }) => {
      const text = isNewTemplate ? `<p>${i18n.t('amp.agreement.shareInfoType')}${dataItems.map((val) => `<span class="${val.sensitiveData ? 'bold' : ''}">${val.itemDesc}</span>`).join(lang === 'zh' ? '、' : ',')}</p>` : `<p>${i18n.t('amp.agreement.shareInfoName')}${htmlEncode(personalType)}</p>`;
      return `<div class="share-content">
        <p>${i18n.t('amp.agreement.thirdCompanyColons')}${htmlEncode(name)}</p>
        ${serviceType ? `<p>${i18n.t('amp.agreement.sdkTypeColons')}${htmlEncode(serviceType)}</p>` : ''}
        ${text}
        <p>${i18n.t('amp.agreement.thirdPurpose')}${htmlEncode(purpose)}</p>
        ${scene ? `<p>${i18n.t('amp.agreement.sceneLable')}${htmlEncode(scene)}</p>` : ''}
        ${shareType ? `<p>${i18n.t('amp.agreement.shareType')}${htmlEncode(shareType)}</p>` : ''}
        ${officialPrivacyUrl ? `<p>${i18n.t('amp.agreement.thirdInfoRule')}${generateUrl(htmlEncode(officialPrivacyUrl))}</p>` : ''}
      </div>`
    }).join('')}
  </div>`;
  thirdSharedDom.innerHTML = str;
}

function generateUrl(value) {
  if(!checkUrl(value)) {
    return `<a href="${value}">${value}</a>`;
  }
  return value;
}

function showLables(item, lang) {
  const list = [];
  (item.privacyLabels || []).forEach((label) => {
    list.push(...label.dataItems);
  });
  return list.map((val) => `<span class="${val.sensitiveData ? 'bold' : ''}">${val.itemDesc}</span>`).join(lang === 'zh' ? '、' : ',');
}

function handleThirdSdkInfo(diff, lang, isNewTemplate) {
  let thirdSdkDom = document.getElementById('third-sdk');
  let thirdSdkInfo = agreementInfos.thirdSdkInfo.sdkInfos;
  let initStr = `<h5 class="sdk-title"> ${1 + diff}. ${i18n.t('amp.agreement.toastThirdSdkInfo')}</h5><p class="sdk-content">
    ${i18n.t('amp.agreement.thirdSdkInfoDesc')}
  </p><div id="sdk-info"></div>`;
  thirdSdkDom.innerHTML = initStr;
  let sdkInfoDom = document.getElementById('sdk-info');
  let str = '';
  for (let i = 0; i < thirdSdkInfo.length; i++) {
    str +=
      `<div><p>${i + 1}、SDK ${i + 1}</p>
        <p>
          <span>${i18n.t('amp.agreement.thirdCompanyColons')}</span>
          <span>${htmlEncode(thirdSdkInfo[i].providerName)}</span>
        </p>
        <p>
          <span>${i18n.t('amp.agreement.sdkTypeColons')}</span>
          <span>${htmlEncode(thirdSdkInfo[i].name)}</span>
        </p>
        ${isNewTemplate ? `<p>
          <span>${i18n.t('amp.agreement.collectInfoType')}</span>
          <span>${showLables(thirdSdkInfo[i], lang)}</span>
        </p>
        <p>
          <span>${i18n.t('amp.agreement.thirdPurpose')}</span>
          <span>${htmlEncode(thirdSdkInfo[i].purpose)}</span>
        </p>` : ''}
        <p>
          <span>${i18n.t('amp.agreement.sceneLable')}</span>
          <span>${htmlEncode(thirdSdkInfo[i].scene) || ''}</span>
        </p>
        <p>
          <span>${i18n.t('amp.agreement.collectType')}</span>
          <span>${htmlEncode(thirdSdkInfo[i].collectType) || ''}</span>
        </p>
        <p>
          <span>${i18n.t('amp.agreement.handleThirdInfo')}</span>
          <a class='privacy-word' href="${thirdSdkInfo[i].privacyDeclare}">${htmlEncode(thirdSdkInfo[i].privacyDeclare)}</a>
        </p><div id="sdk-ul${i}">`;
    let ulStr = '';
    if (!isNewTemplate) {
      const classMap = { 0: 'normal', 1: 'bold', undefined: 'normal' };
      for (let j = 0; j < thirdSdkInfo[i].privacyLabels.length; j++) {
        let contactArr = [];
        const item = thirdSdkInfo[i].privacyLabels[j];
        let isSensitive = false;
        for (let k = 0; k < item.dataItems.length; k++) {
          contactArr.push(`<span class="${classMap[item.dataItems[k].sensitiveData]}">${item.dataItems[k].itemDesc}</span>`);
          if (item.dataItems[k].sensitiveData) {
            isSensitive = true;
          }
        }
        ulStr += `<p>${i18n.t('amp.agreement.forThingAndCollect', { do: `<span class="${isSensitive ? 'bold' : 'normal'}">${item.sceneReason}</span>`, permission: contactArr.join('、') })}</p>`;
      }
    }
    str = str + ulStr + `</div></div>`;
    sdkInfoDom.innerHTML = str;
  }
}

function checkHasData(data) {
  return data && JSON.stringify(data) !== '{}';
}

function setPersonInfoShow(data, indexObj) {
  if (checkHasData(data)) {
    indexObj.second++;
    indexObj.showIndex = indexObj.index + indexObj.second;
    return 'block';
  }
  return 'none';
}

function handlePersonInfo(diff, isMetaService) {
  let personDom = document.getElementById('manage-person');
  const indexObj = { index: 2 + diff + '.', second: 0 };
  let manageStr = '';
  let hasData = false;
  if (agreementInfos.extInfo.managePersonalInfo) {
    const { managePersonalInfo: { infoAccess, infoCancel, infoDelete, infoModify, serviceStop} } = agreementInfos.extInfo;
    if(checkHasData(infoAccess) || checkHasData(infoCancel) || checkHasData(infoDelete) || checkHasData(infoModify) || checkHasData(serviceStop)) {
      hasData = true;
    }
    manageStr = `
      <div style="display: ${setPersonInfoShow(infoAccess, indexObj)}">
        <p>${indexObj.showIndex} ${i18n.t('amp.agreement.personalContactInfoSee')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.accessInfo', { path: htmlEncode(infoAccess.personalSettingPath), info: htmlEncode(infoAccess.personalType) })}</span>
        </p>
      </div>
      <div style="display: ${setPersonInfoShow(infoModify, indexObj)}">
        <p>${indexObj.showIndex} ${i18n.t('amp.agreement.personalContactInfoUpdate')}</p>
        <p>${i18n.t('amp.agreement.personalContactInfoUpdateDesc')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.modifyInfo', { path: htmlEncode(infoModify.personalSettingPath), info:htmlEncode(infoModify.personalType)  })}</span>
        </p>
      </div>
      <div style="display: ${setPersonInfoShow(infoDelete, indexObj)}">
        <p>${indexObj.showIndex} ${i18n.t('amp.agreement.personalContactInfoDelete')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.deleteInfo', { path: htmlEncode(infoDelete.personalSettingPath), info: htmlEncode(infoDelete.personalType) })}</span>
        </p>
      </div>
      <div style="display: ${setPersonInfoShow(infoCancel, indexObj)}">
        <p>${indexObj.showIndex} ${i18n.t('amp.agreement.personalContactInfoCancel')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.cancelAgreement', { agree: htmlEncode(infoCancel.serviceType), path: htmlEncode(infoCancel.personalSettingPath) })}</span>
        </p>
      </div>
      <div style="display: ${setPersonInfoShow(serviceStop, indexObj)}">
        <p>${indexObj.showIndex} ${i18n.t('amp.agreement.personalContactInfoStop')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.personalContactInfoTo', { path: htmlEncode(serviceStop.personalSettingPath) })}</span>
          <span>${i18n.t('amp.agreement.personalContactInfoStopYours')}</span>
        </p>
      </div>
      <p>${i18n.t('amp.agreement.personalContactInfoStopDesc')}</p>
    `;
  }
  let appDesc = hasData ? `<p>${i18n.t('amp.agreement.personalContactInfoDescApp')}</p>` : '';
  let str = `
    <h5 class="person-title">${indexObj.index} ${i18n.t('amp.agreement.personalContactInfo')}</h5>
    ${isMetaService
    ? `<p>${i18n.t('amp.agreement.personalContactInfoDesc')}</p>`
    : `${appDesc}${manageStr}`}
  `;
  personDom.innerHTML = str;
}

function handleOldPersonInfo(diff, isMetaService) {
  let personDom = document.getElementById('manage-person');
  const index = 2 + diff + '.';
  let manageStr = '';
  if (agreementInfos.extInfo.managePersonalInfo) {
    const { managePersonalInfo: { infoAccess, infoCancel, infoDelete, infoModify, serviceStop } } = agreementInfos.extInfo;
    manageStr = `
      <div>
        <p>${index + 1} ${i18n.t('amp.agreement.personalContactInfoSee')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.accessInfo', { path: htmlEncode(infoAccess.personalSettingPath), info: htmlEncode(infoAccess.personalType) })}</span>
        </p>
      </div>
      <div>
        <p>${index + 2} ${i18n.t('amp.agreement.personalContactInfoUpdate')}</p>
        <p>${i18n.t('amp.agreement.personalContactInfoUpdateDesc')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.modifyInfo', { path: htmlEncode(infoModify.personalSettingPath), info: htmlEncode(infoModify.personalType) })}</span>
        </p>
      </div>
      <div>
        <p>${index + 3} ${i18n.t('amp.agreement.personalContactInfoDelete')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.deleteInfo', { path: htmlEncode(infoDelete.personalSettingPath), info: htmlEncode(infoDelete.personalType) })}</span>
        </p>
      </div>
      <div>
        <p>${index + 4} ${i18n.t('amp.agreement.personalContactInfoCancel')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.cancelAgreement', { agree: htmlEncode(infoCancel.serviceType), path: htmlEncode(infoCancel.personalSettingPath) })}</span>
        </p>
      </div>
      <div>
        <p>${index + 5} ${i18n.t('amp.agreement.personalContactInfoStopOld')}</p>
        <p class="d-flex align-itams-center flex-wrap mt-4">
          <span>${i18n.t('amp.agreement.personalContactInfoTo', { path: htmlEncode(serviceStop.personalSettingPath) })}</span>
          <span>${i18n.t('amp.agreement.personalContactInfoStopYoursOld')}</span>
        </p>
        <p>${i18n.t('amp.agreement.personalContactInfoStopDesc')}</p>
      </div>
    `;
  }
  let str = `
    <h5 class="person-title">${index} ${i18n.t('amp.agreement.personalContactInfo')}</h5>
    ${isMetaService
    ? `<p>${i18n.t('amp.agreement.personalContactInfoDesc')}</p>`
    : `<p>${i18n.t('amp.agreement.personalContactInfoDescAppOld')}</p>${manageStr}`}
  `;
  personDom.innerHTML = str;
}

function handleStorage(diff) {
  const index = 3 + diff;
  let storageInfo = agreementInfos.extInfo.storageInfo;
  let personDom = document.getElementById('storage-info');
  let arr = [];
  let periodStr = '';
  if (!storageInfo.storagePeriod || storageInfo.storagePeriod === '-1') {
    periodStr = `${index}.1 ${i18n.t('amp.agreement.storageInfoSecondDesc')}`;
  } else {
    periodStr = `${i18n.t('amp.agreement.previewStorageInfoSecondDesc', { index: `${index}.1`, storagePeriod: htmlEncode(storageInfo.storagePeriod) })}`;
  }
  let str = `<h5>${i18n.t('amp.agreement.previewStorageInfoFirstDesc', { index: `${index}.` })}</h5>
  <p>${periodStr} </p>
  <p>${i18n.t('amp.agreement.previewStorageInfoFourthDesc', { index: `${index}.2`, country: htmlEncode(storageInfo.country) })}</p>`;
  if (storageInfo.isCrossBorder) {
    for (let i = 0; i < storageInfo.crossBorderDeclarations[0].dataItems.length; i++) {
      arr.push(storageInfo.crossBorderDeclarations[0].dataItems[i].itemDesc);
    }
    str =
      str + `<p>${i18n.t('amp.agreement.previewStorageInfoFifthDesc', {
        index: `${index}.3`,
        crossBorderReason: htmlEncode(storageInfo.crossBorderReason),
        crossBorderReceiveName: htmlEncode(storageInfo.crossBorderReceiveName),
        itemDesc: arr.join('、'),
        crossBorderCountry: htmlEncode(storageInfo.crossBorderCountry),
      })}<p>`;
  }
  personDom.innerHTML = str;
}

function handleContactInfo(diff, isMetaService) {
  let contactInfo = agreementInfos.extInfo.contactInfo;
  let contactDom = document.getElementById('contact-info');
  let str = `<h5>${
    4 + diff
  }. ${i18n.t('amp.agreement.contactInfo')}</h5>`;
  if (!isMetaService) {
    str += `<p>${i18n.t('amp.agreement.contractUs')}</p>`
  }
  if (contactInfo.phoneNum && contactInfo.phoneNum.length) {
    for (let i = 0; i < contactInfo.phoneNum.length; i++) {
      str = str + `<p><span>${i18n.t('amp.agreement.previewContactInfoPhone')}</span><span>${htmlEncode(contactInfo.phoneNum[i])}</span></p>`;
    }
  }
  if (contactInfo.email && contactInfo.email.length) {
    for (let i = 0; i < contactInfo.email.length; i++) {
      str = str + `<p><span>${i18n.t('amp.agreement.previewContactInfoEmail')}</span><span>${htmlEncode(contactInfo.email[i])}</span></p>`;
    }
  }
  if (contactInfo.companyAddress) {
    str = str + `<p><span>${i18n.t('amp.agreement.previewContactInfoAddress')}</span><span>${htmlEncode(contactInfo.companyAddress)}</span></p>`;
  }
  if (contactInfo.customContactInfo) {
    str = str + `<p>${htmlEncode(contactInfo.customContactInfo)}</p>`;
  }
  str += `<p>${i18n.t('amp.agreement.contactInfoDesc')}</p>`;
  contactDom.innerHTML = str;
}

function handleTime(isRtlDirection) {
  const className = isRtlDirection ? 'text-left' : 'text-right';
  const contactDom = document.getElementById('date-info');
  const updateTimeDom = document.getElementById('update-time');
  let updateTime = formatTime(agreementInfo.updateTime);
  let effectiveTime = formatTime(agreementInfos.baseInfo.effectiveTime);
  contactDom.innerHTML = `<div class="${className}"><span>${i18n.t('amp.agreement.effectiveDate')}</span><span>${effectiveTime}</span></div>`;
  updateTimeDom.innerHTML = `<span class="font-secondary">${i18n.t('amp.agreement.updateDate')}</span><span class="font-secondary">${updateTime}</span>`;
}

function formatTime(time) {
  const date = new Date(time);
  return `${date.getFullYear()}.${date.getMonth() + 1}.${date.getDate()}`;
}

// 定义一个简易的i18n，可以避免引入vue和vue-i18n的js文件，减少请求体积，注意：只处理无参数和带变量参数情况，该页面只有这两种情况
function initI18n(lang) {
  const { en_US, zh_CN, hk, tw, ug, bo } = AGC_I18N_AMP;
  const messages = {
    zh: zh_CN,
    en: en_US,
    'zh-Hant-HK': hk,
    'zh-Hant-TW': tw,
    ug,
    bo,
  };

  const t = function(key, params = {}) {
    let langText = messages[lang][key];
    if (!langText) {
      return key;
    }
    if (JSON.stringify(params) !== '{}') {
      Object.keys(params).forEach(key => {
        langText = langText.replace(`{${key}}`, params[key]);
      });
    }
    return langText;
  }

  window.i18n = {
    t,
  };
}

function handleDomI18n() {
  const domList = document.body.querySelectorAll('.need-use-i18n');
  domList.forEach(dom => {
    dom.innerText = i18n.t(dom.getAttribute('data-i18n'));
  });
}

function handleTotalTitle(baseInfo, isMetaService, isNewTemplate) {
  if (isNewTemplate) {
    const appTitle = i18n.t(isMetaService ? 'amp.agreement.autoServiceIntroduce' : 'amp.agreement.appIntroduce', {
      appName: `<span>${htmlEncode(baseInfo.appName)}</span>`,
      devName: `<span>${htmlEncode(baseInfo.companyName)}</span>`,
      desc: `<span>${htmlEncode(baseInfo.briefDesc)}</span>`,
    });
    document.getElementById('firstDesc').innerHTML = appTitle;
  } else {
    const appTitle = i18n.t('amp.agreement.harmonyAppTitleOld', {
      appName: `<span>${htmlEncode(baseInfo.appName)}</span>`,
      devName: `<span>${htmlEncode(baseInfo.companyName)}</span>`,
      desc: `<span>${htmlEncode(baseInfo.briefDesc)}</span>`,
    });
    const metaServiceTitle = i18n.t('amp.agreement.totalTitleNew', {
      appName: `<span>${htmlEncode(baseInfo.appName)}</span>`,
      devName: `<span>${htmlEncode(baseInfo.companyName)}</span>`,
    });
    document.getElementById('firstDesc').innerHTML = isMetaService ? metaServiceTitle : appTitle;
  }
}

function handleVersionAndSummary(isMetaService, isNewTemplate) {
  const { versionChangeDescs = [], abstracts } = agreementInfos.extInfo;
  if (!isMetaService && versionChangeDescs.length) {
    let versionStr = `<h5>${i18n.t(isNewTemplate ? 'amp.agreement.versionDiffTitle' : 'amp.agreement.versionDiffTitleOld')}</h5>`;
    versionChangeDescs.forEach(item => {
      versionStr += `
        <p>${htmlEncode(item.chapter)} ${i18n.t('amp.agreement.versionDiffCharSuffix')} ${htmlEncode(item.desc)}</p>
      `;
    })
    document.getElementById('version-desc').innerHTML = versionStr;
  }
  if (abstracts) {
    document.getElementById('summary').innerHTML = `<h5>${i18n.t('amp.agreement.summaryInfoTitle')}</h5><p>${htmlEncode(abstracts)}</p>`;
  }
}

function handleCollectPersonInfo(isNewTemplate, isMetaService) {
  const { requiredInfo, recommendInfo, adsInfo, fullServiceMode, contractObligationMode, lawRegulationMode } = agreementInfos.personalInfo;
  const { appName } = agreementInfos.baseInfo;
  let index = 0;
  if (requiredInfo && isMetaService) {
    index++;
    handleRequire(requiredInfo.sceneItems);
  } else {
    document.getElementById('required-title').style.display = 'none';
  }

  if (fullServiceMode && !requiredInfo && !isMetaService) {
    index++;
    handleFullService(fullServiceMode, appName, index, isNewTemplate);
  }
  if (contractObligationMode) {
    index++;
    handleContract(contractObligationMode, index);
  }
  if (lawRegulationMode) {
    index++;
    handleLaw(lawRegulationMode, index);
  }
  if (recommendInfo) {
    index++;
    handleRecommend(recommendInfo.sceneItems, recommendInfo.closeSetting, index);
  }
  if (adsInfo) {
    index++;
    handleAds(adsInfo, index);
  }
}

function handleCustomInfo(diff) {
  const { customInfos } = agreementInfos.extInfo.customInfo;
  document.getElementById('custom-info').innerHTML = `
    ${customInfos.map((item, index) => `
      <h5>${diff + (index + 4)}. ${htmlEncode(item.title)}</h5>
      <p>${htmlEncode(item.customInfoDesc)}</p>
    `).join('')}
  `;
}

function handleOldCustomInfo(diff) {
  const { title, customInfoDesc } = agreementInfos.extInfo.customInfo;
  document.getElementById('custom-info').innerHTML = `
    <h5>${diff + 3}. ${htmlEncode(title)}</h5>
    <p>${htmlEncode(customInfoDesc)}</p>
  `;
}

