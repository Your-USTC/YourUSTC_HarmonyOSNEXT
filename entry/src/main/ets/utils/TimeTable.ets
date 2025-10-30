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

export const example: string = '[[[{"name":"批判性思维与英语沟通","teacher":"Bradley Johnson","weekOfTerm":[2],"timeSpan":[1,2],"location":"5106","id":"FL1106A.01 [2]"}],[],[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[3,4],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[{"name":"计算机程序设计","teacher":"李卫海","weekOfTerm":[2],"timeSpan":[6,7],"location":"3A212","id":"CS1003.H2 [3]"}],[],[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[8,9],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[],[],[],[]],[[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[1,2],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[{"name":"线性代数(B1)","teacher":"赵晨","weekOfTerm":[2],"timeSpan":[3,4],"location":"3C103","id":"MATH1009.06 [4]"}],[],[],[],[],[{"name":"习近平新时代中国特色社会主义思想概论","teacher":"陈慧瑞","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"1302","id":"MARX1014.06 [3]"}],[],[],[],[],[]],[[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[1,2],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[],[],[],[],[],[],[],[],[],[]],[[{"name":"线性代数(B1)","teacher":"赵晨","weekOfTerm":[2],"timeSpan":[1,2],"location":"3C103","id":"MATH1009.06 [4]"}],[],[{"name":"力学A(L)","teacher":"王春成","weekOfTerm":[2],"timeSpan":[3,4],"location":"2106","id":"PHYS1001AL.01 [4]"}],[],[],[{"name":"基础体育","teacher":"刘德海","weekOfTerm":[2],"timeSpan":[6,7],"location":"","id":"PE00001.28 [1]"}],[],[{"name":"思想道德与法治","teacher":"刘海龙","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"1202","id":"MARX1012.12 [2.5]"}],[],[],[],[],[]],[[],[],[{"name":"数学分析(B1)","teacher":"王建伟","weekOfTerm":[2],"timeSpan":[3,4],"location":"5403","id":"MATH1006.08 [6]"}],[],[],[{"name":"计算机程序设计","teacher":"李卫海","weekOfTerm":[2],"timeSpan":[6,7],"location":"3A212","id":"CS1003.H2 [3]"}],[],[{"name":"先进制造实践","teacher":"倪青, 刘志刚, ...","weekOfTerm":[2],"timeSpan":[8,9,10],"location":"","id":"ME2503.01 [2]"}],[],[],[],[],[]],[[],[],[],[],[],[],[],[],[],[],[],[],[]],[[],[],[],[],[],[],[],[],[],[],[],[],[]]]'
