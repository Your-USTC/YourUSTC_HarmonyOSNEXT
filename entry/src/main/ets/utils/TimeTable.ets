export const timeTableQueryJS = `
function pressButton(XPath) {
    document.evaluate(XPath,
        document,
        null,
        XPathResult.FIRST_ORDERED_NODE_TYPE,
        null).singleNodeValue.click();
}

function executeProgram() {
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
                try {
                    const className = target.querySelector(".title").innerText;
                    const teacherList = target.querySelectorAll(".teacher .name");
                    const teacherName = Array.from(teacherList).map(element => element.innerText).join(", ");
                    const startTime = target.querySelector(".start").innerText;
                    const endTime = target.querySelector(".end").innerText;
                    const timeSpan = target.querySelector(".timespan").innerText;
                    classesOfDay.push([className, teacherName, startTime, endTime, timeSpan]);
                } catch (error) { }
            }
        }
        return classesOfDay;
    };
    return ([0, 1, 2, 3, 4, 5, 6].map(i => getClassesOfDay(i)));
}

function waitForDOMChange() {
    return new Promise((resolve) => {
        const observer = new MutationObserver(() => {
            observer.disconnect();
            resolve();
        });
        observer.observe(document, { childList: true, subtree: true, attributes: true });
    });
}

async function main() {
    pressButton('/html/body/div[2]/div[2]/div[3]/button[2]');
    await waitForDOMChange();
    return JSON.stringify(executeProgram());
}

function showMessage(messageShown) {
    const box = document.createElement('div');
    box.id = 'console-tip-box';
    box.innerHTML = messageShown;

    Object.assign(box.style, {
        position: 'fixed',
        left: '50%',
        top: '50%',
        transform: 'translate(-50%, -50%)',
        padding: '10px 14px',
        background: '#0f0',
        color: '#000',
        fontSize: '14px',
        borderRadius: '6px',
        boxShadow: '0 2px 8px rgba(0,0,0,.3)',
        zIndex: '999999',
        transition: 'opacity .3s',
        opacity: '0'
    });

    document.body.appendChild(box);
    requestAnimationFrame(() => box.style.opacity = '1');

    setTimeout(() => {
        box.style.opacity = '0';
        box.addEventListener('transitionend', () => box.remove(), { once: true });
    }, 3000);
}

let timeTable = '';
main().then(result => { timeTable = result; showMessage('课表获取成功！') });
`;