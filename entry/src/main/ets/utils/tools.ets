
export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function getContArray(range: number[][], returnString: boolean = false): string[] | number[] {
  // 返回一个包含range的连续数字的数组（例如[[1,3],[5,6]]返回[1,2,3,5,6]），returnString为true时，返回类型为string[]；否则为number[]。你可以在引用的后面加上as string[]或as number[]
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
    + (week - 1) * 604800000 // 第几周
    + day * 86400000 // 第几天，不-1是因为教务系统中一周从周日开始
    + surplus; // 第几节课结束;
}