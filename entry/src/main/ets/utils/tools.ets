
export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 构造连续整数数组
 * (可以在调用的后面加上 as number[] 或 as string[] )
 * @param range 取值范围 (例如: 输入 [[1,3],[5,6]], 返回 [1,2,3,5,6] )
 * @param returnString 返回类型 (默认返回 number[], 为 true 则返回 string[] )
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

export function dateTimeToTimestamp(dateTime: string): number {
  const date = new Date(dateTime);
  return Math.floor(date.getTime());
}

export function getClassTimestamp(termBeginDate: string, week: number, day: number, surplus: number): number {
  return dateTimeToTimestamp(termBeginDate)
    + (week - 1) * 604800000    // 第几周
    + day * 86400000            // 第几天，不-1是因为教务系统中一周从周日开始
    + surplus;                  // 第几节课结束
}

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
