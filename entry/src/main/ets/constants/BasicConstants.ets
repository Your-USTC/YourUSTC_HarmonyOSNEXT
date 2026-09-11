import { i18n } from "@kit.LocalizationKit";
import { deviceInfo } from "@kit.BasicServicesKit";
import { common } from '@kit.AbilityKit'

export const FULL_TIME_FORMAT: Intl.DateTimeFormatOptions = {
  year: "numeric",
  month: 'numeric',
  day: 'numeric',
  hour: '2-digit',
  minute: 'numeric',
  second: 'numeric',
  hourCycle: i18n.System.is24HourClock() ? 'h23' : 'h12'
};

export const currentAppVersion: string = "2.2.2";
export const currentScheduleVersion: string = "2.1.0"; // 从 2.1.0 以后未更改
export const currentDataVersion: string = "2.2.0"; // 从 2.2.0 以后未更改

export const deviceType: string = deviceInfo.deviceType;

let _hostContext: common.UIAbilityContext | null;

export function initHostContext(context: common.UIAbilityContext) {
  _hostContext = context;
}

export function hostContext(): common.UIAbilityContext {
    if (!_hostContext) throw new Error("配置未初始化，请先调用 initConfig");
    return _hostContext;
}