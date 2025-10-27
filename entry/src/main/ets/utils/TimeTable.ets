export const timeTableQueryJS = `
function getWeekNumber(str) {
    const parts = str.split(',');
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