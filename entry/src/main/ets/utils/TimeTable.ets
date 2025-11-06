import { classAttribute, obtainedData } from '../pages/Schedule';
import { SCHEDULE_KEY, START_TIME_KEY, millisecondsPerWeek } from './UnifyPreference';
import UnifiedPreferences from './UnifyPreference';
import * as tools from './tools';

export const timeTableQueryJS = `
function getWeekNumber(str) {
    const parts = str.replace(/[^0-9,-]/g, '').split(',');
    const result = [];
    for (const part of parts) {
        if (part.includes('-')) {
            const [start, end] = part.split('-').map(Number);
            for (let i = start; i <= end; i++) {
                result.push(i);
            }
        } else {
            result.push(Number(part));
        }
    }
    return result;
}

function getTimeTable() {
    const timeTable = document.evaluate(
        "/html/body/div[2]/div[3]/div/div/table",
        document,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null).singleNodeValue;
    const rows = timeTable.getElementsByTagName("tr");
    const getClassesOfDay = dayNumber => {
        let classesOfDay = []
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].hasAttribute("class")) {
                const classesOfWeek = rows[i].getElementsByTagName("td");
                let count = 0;
                target = Array.from(classesOfWeek).find(elem => {
                    if (!elem.hasAttribute("style")) { return ++count > dayNumber; }
                    return false;
                })
                const classList = Array.from(target.querySelectorAll(".c")).map(element => ({
                    name: element.querySelector(".title").innerText,
                    teacher: Array.from(element.querySelectorAll(".teacher .name")).map(elem => elem.innerText).join(", "),
                    weekOfTerm: getWeekNumber(element.querySelector(".time .week").innerText),
                    timeSpan: getWeekNumber(element.querySelector(".timespan").innerText),
                    dayOfWeek: dayNumber,
                    location: element.querySelector(".classroom .name").innerText.trim(),
                    id: element.querySelector(".number").innerText
                }));
                classesOfDay.push(classList);
            }
        }
        return classesOfDay;
    };
    return ([0, 1, 2, 3, 4, 5, 6].map(i => getClassesOfDay(i)));
}

JSON.stringify(getTimeTable());
`
export const timeTableQueryJSShort = `
JSON.stringify(getTimeTable());
`

export const startTimeQueryJS = `
{const startTime = new Date(document.getElementById('startDate').innerText);startTime.getTime().toString();};
`

export const examInfoQueryJS = `
Array.from(document.querySelectorAll('#exams tbody tr')).map(
    tr => {
        const trCells = tr.cells;
        return ({
            courseNo: trCells[0].innerText,
            examType: trCells[1].innerText,
            courseName: trCells[2].innerText,
            examDate: trCells[3].innerText,
            examRoom: trCells[4].innerText,
            examBuilding: trCells[5].innerText,
            examCampus: trCells[6].innerText,
            examInfo: trCells[7].innerText
        })
    }
)
`

/**
 * 比较两个 classAttribute 对象是否完全相同
 * @param a 第一个对象
 * @param b 第二个对象
 * @returns 是否完全相同
 */
function areClassAttributesEqual(a: classAttribute, b: classAttribute): boolean {
  // 基本类型直接比较
  if (a.name !== b.name) return false;
  if (a.teacher !== b.teacher) return false;
  if (a.dayOfWeek !== b.dayOfWeek) return false;
  if (a.location !== b.location) return false;
  if (a.id !== b.id) return false;

  // 数组类型通过辅助函数比较
  if (!tools.areNumberArraysEqual(a.weekOfTerm, b.weekOfTerm)) return false;
  if (!tools.areNumberArraysEqual(a.timeSpan, b.timeSpan)) return false;

  // 所有字段都相同
  return true;
}

export const example: string = '[[[{"name":"批判性思维与英语沟通","teacher":"Bradley Johnson","weekOfTerm":[2],"timeSpan":[1,2],"location":"5106","id":"FL1106A.01 [2]"}],[],[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[3,4],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[{"name":"计算机程序设计","teacher":"李卫海","weekOfTerm":[2],"timeSpan":[6,7],"location":"3A212","id":"CS1003.H2 [3]"}],[],[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[8,9],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[],[],[],[]],[[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[1,2],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[{"name":"线性代数(B1)","teacher":"赵晨","weekOfTerm":[2],"timeSpan":[3,4],"location":"3C103","id":"MATH1009.06 [4]"}],[],[],[],[],[{"name":"习近平新时代中国特色社会主义思想概论","teacher":"陈慧瑞","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"1302","id":"MARX1014.06 [3]"}],[],[],[],[],[]],[[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[1,2],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[],[],[],[],[],[],[],[],[],[]],[[{"name":"线性代数(B1)","teacher":"赵晨","weekOfTerm":[2],"timeSpan":[1,2],"location":"3C103","id":"MATH1009.06 [4]"}],[],[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[3,4],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[],[{"name":"基础体育","teacher":"刘德海","weekOfTerm":[2],"timeSpan":[6,7],"location":"","id":"PE00001.28 [1]"}],[],[{"name":"思想道德与法治","teacher":"刘海龙","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"1202","id":"MARX1012.12 [2.5]"}],[],[],[],[],[]],[[],[],[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[3,4],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[{"name":"计算机程序设计","teacher":"李卫海","weekOfTerm":[2],"timeSpan":[6,7],"location":"3A212","id":"CS1003.H2 [3]"}],[],[{"name":"先进制造实践","teacher":"倪青, 刘志刚, ...","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"","id":"ME2503.01 [2]"}],[],[],[],[],[]],[[],[],[],[],[],[],[],[],[],[],[],[],[]],[[],[],[],[],[],[],[],[],[],[],[],[],[]]]'

class scheduleManager {
  weekDisplayed: number = 0;
  termStart: number = 0;
  weekStart: number = 0;
  weekEnd: number = 0;
  parsedSchedule: classAttribute[][][] = [];
  formattedSchedule: classAttribute[][][] = [];
  currentTime: Date = new Date();
  today: number = 0; // 星期几-1

  getParsedSchedule(): void {
    this.parsedSchedule = JSON.parse(UnifiedPreferences.getSync(SCHEDULE_KEY, '[[[]]]')) as classAttribute[][][];
    this.weekDisplayed = UnifiedPreferences.hasSync(START_TIME_KEY)
      ? Math.ceil((this.currentTime.getTime() - Number(UnifiedPreferences.getSync(START_TIME_KEY))) / millisecondsPerWeek)
      : 1;
    this.today = (this.currentTime.getDay() + 6) % 7;
    this.termStart = Number(UnifiedPreferences.getSync(START_TIME_KEY));
    this.weekStart = UnifiedPreferences.hasSync(START_TIME_KEY)
      ? Number(UnifiedPreferences.getSync(START_TIME_KEY)) + (this.weekDisplayed - 1) * millisecondsPerWeek
      : this.currentTime.getTime();
    this.weekEnd = this.weekStart + 518400000;
  }

  refreshParsedSchedule(routerParams: obtainedData): void {
    try {
      const timeTable = routerParams.timeTable.slice(1, -1).replace(/\\/g, '');
      this.termStart = Number(routerParams.startTime.replace(/[^0-9]/g, ''));
      this.parsedSchedule = JSON.parse(timeTable) as classAttribute[][][];
      UnifiedPreferences.putSync(SCHEDULE_KEY, timeTable);
      UnifiedPreferences.putSync(START_TIME_KEY, this.termStart);
      this.weekDisplayed = Math.ceil((this.currentTime.getTime() - this.termStart) / millisecondsPerWeek);
      this.weekStart = UnifiedPreferences.hasSync(START_TIME_KEY)
        ? Number(UnifiedPreferences.getSync(START_TIME_KEY)) + (this.weekDisplayed - 1) * millisecondsPerWeek
        : this.currentTime.getTime();
      this.weekEnd = this.weekStart + 518400000;
    } catch (err) {
      this.getParsedSchedule();
    }
  }

  getFormattedSchedule(): void {
    this.getParsedSchedule();
    this.formattedSchedule = [];
    for (let i = 0; i <= 20; i++) { // 初始化三个维度
      this.formattedSchedule[i] = [];
      for (let j = 0; j <= 6; j++)
        this.formattedSchedule[i][j] = [];
    }
    for (let i = 0; i <= 6; i++) // 星期几 -1
      if (this.parsedSchedule[i] != undefined) // 防止不存在元素
        for (let j of this.parsedSchedule[i]) // 星期几的每一节课
          for (let k of j) // 叠课判断
            for (let week of k.weekOfTerm)
              this.formattedSchedule[week][i].push(k);
  }

  addSchedule(toChangeInfo: classAttribute) {
    let i: number = toChangeInfo.dayOfWeek;
    let j: number = toChangeInfo.timeSpan[0] - 1;
    if (this.parsedSchedule[i] == undefined)
      this.parsedSchedule[i] = [];
    this.parsedSchedule[i][j].push(toChangeInfo);
    this.refreshParsedSchedule({ timeTable: `[${JSON.stringify(this.parsedSchedule)}]`, startTime: this.termStart.toString() });
    this.getFormattedSchedule();
  }

  deleteSchedule(oriClassInfo: classAttribute) {
    let i: number = oriClassInfo.dayOfWeek;
    let j: number = oriClassInfo.timeSpan[0] - 1;
    for (let k = this.parsedSchedule[i][j].length - 1; k >= 0; k--)
      if (areClassAttributesEqual(oriClassInfo, this.parsedSchedule[i][j][k])) {
        this.parsedSchedule[i][j].splice(k, 1);
        break;
      }
    this.refreshParsedSchedule({ timeTable: `[${JSON.stringify(this.parsedSchedule)}]`, startTime: this.termStart.toString() });
    this.getFormattedSchedule();
  }
}

export default new scheduleManager();