import { classAttribute, obtainedData } from '../constants/ScheduleSources';
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
export const timeTableQueryJSShort = `JSON.stringify(getTimeTable());`

export const startTimeQueryJS = `
(() => {
  const startTime = new Date(document.getElementById('startDate').innerText);
  return startTime.setHours(0, 0, 0, 0);
})();
`

export const examInfoQueryJS = `
(() => {
    const examInfoTable = document.querySelector('#table-content');
    if (examInfoTable == null) {return null;}
    return Array.from(document.querySelectorAll('#exams tbody tr')).map(
        tr => {
            const trCells = tr.cells;
            return ({
                id: trCells[0].innerText,
                type: trCells[1].innerText,
                name: trCells[2].innerText,
                date: trCells[3].innerText,
                classroom: trCells[4].innerText,
                building: trCells[5].innerText,
                campus: trCells[6].innerText,
                info: trCells[7].innerText
            })
        }
    )
})()
`

export const fillInformationJS = `
(() => {
    const inputUID = infoProvider.getUID();
    const inputPwd = infoProvider.getPassword();
    const main = () => {
        const nodeUID = document.getElementById('nameInput');
        const nodePassword = document.querySelector('input[type="password"][maxlength="200"]');
        if (nodeUID && nodePassword) {
            if (inputPwd) {
              document.querySelector('div.eyes-icon.ng-star-inserted').style.pointerEvents = 'none';
            }
            nodeUID.focus();
            nodeUID.value = infoProvider.getUID();
            nodeUID.dispatchEvent(new Event('input', { bubbles: true }));
            nodePassword.focus();
            nodePassword.value = infoProvider.getPassword();
            nodePassword.dispatchEvent(new Event('input', { bubbles: true }));
            document.getElementById('submitBtn').dispatchEvent(
                new MouseEvent('click', { bubbles: true, cancelable: true })
            );
            return true;
        } else { return false; }
    }
    if (main()) { return; }
    const observer = new MutationObserver(() => {
        if (main()) { observer.disconnect(); }
    });
    observer.observe(document.body, { childList: true, subtree: true });
})();
`

/**
 * 比较两个 classAttribute 对象是否完全相同
 * @param a 第一个对象
 * @param b 第二个对象
 * @returns 是否完全相同
 */
export function areClassAttributesEqual(a: classAttribute, b: classAttribute): boolean {
  // 基本类型直接比较
  if (a.name !== b.name) return false;
  if (a.teacher !== b.teacher) return false;
  if (a.dayOfWeek !== b.dayOfWeek) return false;
  if (a.location !== b.location) return false;
  if (a.id !== b.id) return false;
  if (a.color !== b.color) return false;
  if (a.priority !== b.priority) return false;

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
  parsedSchedule: classAttribute[][][] = [[[]]];
  formattedSchedule: classAttribute[][][] = [[[]]]; // 第一层：周数；第二层：星期几；第三层：这一天的所有课，在Schedule.ets中会按优先级排序
  currentTime: Date = new Date();
  today: number = 0; // 星期几-1
  isTermEnd: boolean = false;
  showColorHint: boolean = UnifiedPreferences.getBoolSync('ShowColorHint', true);

  getParsedSchedule(): void {
    this.parsedSchedule = JSON.parse(UnifiedPreferences.getSync(SCHEDULE_KEY, '[[[]]]')) as classAttribute[][][];
    if (UnifiedPreferences.hasSync(START_TIME_KEY)) {
      this.weekDisplayed = Math.ceil((this.currentTime.getTime() - Number(UnifiedPreferences.getSync(START_TIME_KEY))) / millisecondsPerWeek);
      if (this.weekDisplayed > 20) {
        this.weekDisplayed = 1;
        this.isTermEnd = true;
      }
      this.weekStart = Number(UnifiedPreferences.getSync(START_TIME_KEY)) + (this.weekDisplayed - 1) * millisecondsPerWeek;
      this.termStart = Number(UnifiedPreferences.getSync(START_TIME_KEY));
    } else {
      this.weekDisplayed = 1;
      const monday = new Date(this.currentTime);
      monday.setDate(this.currentTime.getDate() + (this.currentTime.getDay() === 0 ? 1 : - (this.currentTime.getDay() - 1)));
      monday.setHours(0, 0, 0, 0);
      this.weekStart = monday.getTime() - 86400000;
      UnifiedPreferences.putSync(START_TIME_KEY, this.weekStart);
      this.termStart = this.weekStart;
      this.isTermEnd = false;
    }
    this.today = (this.currentTime.getDay() + 6) % 7;
    this.weekEnd = this.weekStart + 518400000;
  }

  refreshParsedSchedule(routerParams: obtainedData): void {
    try {
      const timeTable = routerParams.timeTable.slice(1, -1).replace(/\\/g, '');
      this.termStart = Number(routerParams.startTime/*.replace(/[^0-9]/g, '')*/);
      this.parsedSchedule = JSON.parse(timeTable) as classAttribute[][][];

      let courseToColor = new Map<string, string>();
      for (let i of this.parsedSchedule)
        if (i != null)
          for (let j of i)
            if (j != null)
              for (let k of j) {
                if (k.color == undefined) {
                  if (courseToColor.has(k.name)) {
                    k.color = courseToColor.get(k.name) as string;
                  } else {
                    k.color = tools.colorSet[tools.getRandomInt(0, tools.colorSetLen - 1)];
                    courseToColor.set(k.name, k.color);
                  }
                }
                if (k.priority == undefined)
                  k.priority = 5;
              }

      UnifiedPreferences.putSync(SCHEDULE_KEY, JSON.stringify(this.parsedSchedule));
      this.weekDisplayed = Math.ceil((this.currentTime.getTime() - this.termStart) / millisecondsPerWeek);
      if (this.weekDisplayed > 20) {
        this.weekDisplayed = 1;
        if (this.termStart == 0 ) { // 如果没有学期开始信息，将上一个周日作为一周开始
          const monday = new Date(this.currentTime);
          monday.setDate(this.currentTime.getDate() + (this.currentTime.getDay() === 0 ? 1 : -(this.currentTime.getDay() - 1)));
          monday.setHours(0, 0, 0, 0);
          UnifiedPreferences.putSync(START_TIME_KEY, monday.getTime() - 86400000);
          this.isTermEnd = false;
        } else { // 如果有，说明学期结束
          this.isTermEnd = true;
        }
      } else { // 否则说明学期未结束
        UnifiedPreferences.putSync(START_TIME_KEY, this.termStart);
        this.isTermEnd = false;
      }
      this.weekStart = UnifiedPreferences.hasSync(START_TIME_KEY)
        ? Number(UnifiedPreferences.getSync(START_TIME_KEY)) + (this.weekDisplayed - 1) * millisecondsPerWeek
        : this.currentTime.getTime();
      this.weekEnd = this.weekStart + 518400000;
    } catch (err) {
      console.error('parsed');
    }
  }

  getFormattedSchedule(): void {
    this.currentTime = new Date();
    this.getParsedSchedule();
    this.formattedSchedule = [];
    for (let i = 0; i <= 21; i++) { // 初始化三个维度
      this.formattedSchedule[i] = [];
      for (let j = 0; j <= 6; j++)
        this.formattedSchedule[i][j] = [];
    }
    for (let i = 0; i <= 6; i++) // 星期几 -1
      if (this.parsedSchedule[i] != undefined) // 防止不存在元素
        for (let j of this.parsedSchedule[i]) // 星期几的每一节课
          if (j != undefined)
            for (let k of j) // 叠课判断
              for (let week of k.weekOfTerm)
                this.formattedSchedule[week][i].push(k);
  }

  addSchedule(toChangeInfo: classAttribute, changeAllColor: boolean) {
    let i: number = toChangeInfo.dayOfWeek;
    let j: number = toChangeInfo.timeSpan[0] - 1;
    if (this.parsedSchedule[i] == undefined)
      this.parsedSchedule[i] = [];
    if (this.parsedSchedule[i][j] == undefined)
      this.parsedSchedule[i][j] = [];
    this.parsedSchedule[i][j].push(toChangeInfo);

    if (changeAllColor)
      for (let i of this.parsedSchedule)
        if (i != null)
          for (let j of i)
            if (j != null)
              for (let k of j)
                if (k.name === toChangeInfo.name)
                  k.color = toChangeInfo.color;

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

  hideColorHint() {
    UnifiedPreferences.putSync('ShowColorHint', false);
    this.showColorHint = false;
  }
}

export default new scheduleManager();