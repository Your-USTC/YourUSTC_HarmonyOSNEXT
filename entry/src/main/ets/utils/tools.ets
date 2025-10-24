
export function getRandomInt(min: number, max: number): number {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export let numberPickerData: number = 0;
let numRange: string[] = [];
function init(beginNum: number, endNum: number): void {
  for (let i = beginNum; i <= endNum; i++)
    numRange.push(i.toString());
}

