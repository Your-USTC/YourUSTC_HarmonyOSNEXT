
/**
 * 公共工具区
 */

/**
 * 提取文件路径的扩展名（不含分隔符`.`）
 * @param filePath 字符串格式的文件路径
 * @returns 扩展名（无扩展名返回空字符串）
 */
function getFileExtension(filePath: string): string {
  // 处理空字符串、纯空格等无效路径
  if (!filePath || filePath.trim() === '') {
    return '';
  }

  // 统一处理路径分隔符（兼容 Windows\ 和 Unix/），转为小写便于统一判断
  const normalizedPath = filePath.trim().toLowerCase();

  // 定位最后一个`.`的位置（扩展名的分隔符）
  const lastDotIndex = normalizedPath.lastIndexOf('.');

  // 定位最后一个路径分隔符的位置（区分文件名和路径）
  const lastSeparatorIndex = Math.max(
    normalizedPath.lastIndexOf('/'),
    normalizedPath.lastIndexOf('\\')
  );

  // 核心判断逻辑：
  // 1. 最后一个`.`必须在路径分隔符之后（排除路径中的`.`，如 /dir.name/file.txt）
  // 2. 不能是文件名的第一个字符（排除 `.gitignore` 这类无扩展名的隐藏文件）
  // 3. 不能是最后一个字符（排除 `file.` 这类无效格式）
  if (
    lastDotIndex > lastSeparatorIndex &&
      lastDotIndex !== normalizedPath.length - 1 &&
      lastDotIndex !== 0
  ) {
    // 提取扩展名（从`.`的下一位到末尾）
    return normalizedPath.slice(lastDotIndex + 1);
  }

  // 无有效扩展名返回空字符串
  return '';
}

/**
 * 复制（提取）文件扩展名（含分隔符`.`）
 * @param filePath 字符串格式的文件路径
 * @returns 带`.`的扩展名（无扩展名返回空字符串）
 */
function copyFileExtension(filePath: string): string {
  const ext = getFileExtension(filePath);
  return ext ? `.${ext}` : '';
}

/**
 * 课程颜色随机表
 */
export const colorSet: string[] = [
  "#DDFF8899", "#DDFFF5C4", "#DDFF2C75",
  "#DD00F5C4", "#DDCCBBFF", "#DDAEDEFF", "#DDFFDD00",
  "#DDB7FFFA", "#DDA4FFD6", "#DDD7FF9C", "#DDFFE690",
  "#DDFFAF9C", "#DDFF9100", "#DDCAE1E6", "#DD0093AB",
  "#DD7D6FFF", "#DD4377FF", "#DD66B78B", "#DD66E5FF",
  "#DDF0DFCC", "#DD8C96FF", "#DD2196F3", "#DD1DE9B6",
  "#DDFF1720", "#DD7DACFF", "#DD6AE1E6", "#DDFFC7CD",
  "#DD7BD8E3", "#DD009348", "#DDFF7FB6", "#DDAE3EFF"
];
export const colorSetLen = colorSet.length;

/**
 * 将 #RGB 系列颜色值转换为 RGBA 数值（0-255 范围）
 * @param color 支持格式：#RGB、#RGBA、#RRGGBB、#RRGGBBAA（必须以 # 开头）
 * @returns number[] [r: number; g: number; b: number; a: number] RGBA 数值对象（范围 0-255）
 */
export function stringToRgba(color: string): number[] {
  // 正则表达式匹配所有合法格式（忽略大小写）
  const regex = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/;
  const match = color.match(regex);
  let r = 255, g = 199, b = 205, a = 255; // 默认不透明
  if (!match) {
    return [a, r, g, b];
  }
  let hex = match[1].toLowerCase();
  // 处理短格式（#RGB/#RGBA）：扩展为长格式
  if (hex.length === 3 || hex.length === 4) {
    hex = hex.split('').map(char => char.repeat(2)).join('');
  } else if (hex.length === 8) {
    // 提取各通道值（16进制转10进制）
    a = parseInt(hex.slice(0, 2), 16);
    r = parseInt(hex.slice(2, 4), 16);
    g = parseInt(hex.slice(4, 6), 16);
    b = parseInt(hex.slice(6, 8), 16);
  } else {
    r = parseInt(hex.slice(0, 2), 16);
    g = parseInt(hex.slice(2, 4), 16);
    b = parseInt(hex.slice(4, 6), 16);
  }
  // 确保 RGB 值在 0-255 范围内（防止异常值）
  a = Math.max(0, Math.min(255, a));
  r = Math.max(0, Math.min(255, r));
  g = Math.max(0, Math.min(255, g));
  b = Math.max(0, Math.min(255, b));
  return [a, r, g, b];
}

/**
 * 本地化星期表达
 */
export const weekTranslate: ResourceStr[] = [
  $r('app.string.monday'), $r('app.string.tuesday'), $r('app.string.wednesday'), $r('app.string.thursday'), $r('app.string.friday'), $r('app.string.saturday'), $r('app.string.sunday')
];

/**
 * 生成随机整数
 * @param min 最小值（包含本数）
 * @param max 最大值（包含本数）
 * @returns 随机整数
 */
export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 构造连续整数数组
 * @param range 取值范围 (例如: 输入 [[1,3],[5,6]], 返回 [1,2,3,5,6] )
 * @param returnString 返回类型 (默认返回 number[], 为 true 则返回 string[] )
 * @returns string[] 或 number[] (可以在调用的后面加上 as number[] 或 as string[] )
 */
export function getContArray(range: number[][], returnString: boolean = false): string[] | number[] {
  if (returnString) {
    let res: string[] = [];
    for (let single of range) {
      for (let i = single[0]; i <= single[1]; i++) {
        res.push(i.toString());
      }
    }
    return res;
  } else {
    let res: number[] = [];
    for (let single of range) {
      for (let i = single[0]; i <= single[1]; i++) {
        res.push(i);
      }
    }
    return res;
  }
}

/**
 * 格式化整数数组
 * @param array 离散数组 (例如: 输入 [1,2,4,5] 返回 '1-2, 4-5' )
 * @returns 空字符串返回 '---'，否则返回表示区间的字符串
 */
export function shrinkContArrayToString(array: number[]): string {
  if (array.length == 0) {
    return '---';
  }
  let res: string = array[0].toString();
  let i: number;
  for (i = 1; i < array.length; i++)
    if (array[i] != array[i - 1] + 1)
      res = res + `-${array[i - 1]}, ${array[i]}`;
  return res + `-${array[i - 1]}`;
}

/**
 * 获取课程时间戳
 * @param termBeginDate 学期开始时间
 * @param week 周数
 * @param day 一周的天数（从周日开始）
 * @param surplus 一天内的时间
 * @returns 课程开始的时间戳
 */
export function getClassTimestamp(termBeginDate: number, week: number, day: number, surplus: number): number {
  return termBeginDate
    + (week - 1) * 604800000    // 第几周
    + day * 86400000            // 第几天，不“减1”是因为教务系统中一周从周日开始
    + surplus;                  // 第几节课结束
}

/**
 * 将时间戳转换为格式字符串
 * @param timestamp 时间戳
 * @param format 日期格式，默认为 'yyyy-MM-DD'
 * @returns 表示日期的字符串
 */
export function timestampToDateTime(timestamp: number, format: string = 'yyyy-MM-DD'): string {
  const date = new Date(timestamp);

  const year = date.getFullYear().toString();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');

  return format
    .replace('yyyy', year)
    .replace('MM', month)
    .replace('DD', day);
}

export function areNumberArraysEqual(arr1: number[], arr2: number[]): boolean {
  // 先比较长度，长度不同直接返回 false
  if (arr1.length !== arr2.length) return false;
  // 逐个比较元素
  for (let i = 0; i < arr1.length; i++) {
    if (arr1[i] !== arr2[i]) return false;
  }
  return true;
}

/**
 * 格式化时间差
 * 根据指定的类型返回两个时间戳之间相差的天数、小时数或分钟数
 *
 * @param start - 开始时间戳（毫秒）
 * @param end - 结束时间戳（毫秒）
 * @param type - 计算类型：
 *               0 = 返回相差的天数
 *               1 = 返回相差的小时数（除去整天后的剩余小时）
 *               2 = 返回相差的分钟数（除去整小时后的剩余分钟）
 * @returns 根据类型返回对应的时间差值（向下取整）
 */
export function formatTimeDiff(start: number, end: number, type: number): number {
  const diffSec = Math.abs(end - start) / 1000;
  switch(type) {
    case 0:
      return Math.floor(diffSec / 86400);
    case 1:
      return Math.floor((diffSec % 86400) / 3600);
    case 2:
      return Math.floor((diffSec % 3600) / 60);
  }
  return 0;
}
