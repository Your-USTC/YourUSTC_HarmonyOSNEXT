
import UnifiedPreferences from '../utils/UnifyPreference';
import { LAST_DAY_KEY, TOTAL_DAYS_KEY, CONSECUTIVE_DAYS_KEY, CONTENT_KEY } from '../utils/UnifyPreference';

export class CheckInTools {
  private static CHECK_IN_CONTENT_LIST: string[] = [
    '呐呐，作业写完了吗？该不会是……一个字都没动吧？噗——真是活该！', // 0
    '喂！早饭吃了吗？不会又饿着肚子吧？要是低血糖晕倒了，我可不会去医务室看你这种不爱惜自己的杂鱼的！',
    '签到完成！今天的课程好像很难呢~对你来说肯定很吃力吧？需要我这个天才来教教你吗？……求我呀~！',
    '诶~？这就签到了吗？还以为你会直接睡过头呢！……嘛，勉强表扬你一下下好了，就一下下！',
    '哼~！终于睡醒了吗？再不签到的话，今天的课表可就要哭鼻子了哦？',
    '啊啦啦~脸色好差呢，昨晚又熬夜了吧？真是拿你没办法呢，这样下去可是会秃头的哦？', // 5
    '好了，签完到了就赶紧出发吧！磨磨蹭蹭的，是想迟到然后被老师骂哭吗？……我可不会安慰你哦！',
    '滴——学生卡',
    '签到！今天也是防止人类大脑退化实验的志愿者之一。',
    '只要我签到的速度够快，懒惰就追不上我。',
    '嗨~想我了吗？', // 10
    '一天了！生产队的驴都不敢这么歇！',
    '已醒，勿念',
    '别问我心里有没有你，我课表里都是你。',
    '签到成功！如果觉得辛苦，没关系，明天会更辛苦的。',
    '报告！身体已成功搬运至教室/图书馆，灵魂正在路上。', // 15
    '您的‘困’兽已被暂时封印，有效期至下一堂无聊的课。',
    '签到成功！所以……昨晚说要早睡，你做到了吗？',
    '𝑪𝒊𝒂𝒍𝒍𝒐～(∠・ω < )⌒★',
    '哈——啊——（打哈欠）这么早就要服侍你签到，我好困啊……都怪你，笨蛋！',
    '哦？还知道中午要来签个到？还以为你的脑子跟上午一起被消化掉了呢！', // 20
    '喂喂喂！这么晚还不睡是在干嘛？想猝死然后让我换个聪明点的主人吗？……快、快去睡觉啊！💢',
    '需要我借你点智商吗？……算了，借了你可能也还不起，略略略~',
    '需要我帮你把‘困倦’技能点调低一些吗？……不过你好像天生就是满级呢，噗！',
    '存在先于本质，签到先于学习。——鲁迅（没说过）',
    '是我签到了今天，还是今天签到了我？', // 25
    '您订购的“崭新一天”已到货，请签收',
    '签到有什么用？问得好，但你还是点了。',
    '可……可恶！我想不到新的签到词了！(；´д｀)ゞ…你给出几个点子？',
    '早八人，早八魂！',
    '签到成功！今天演得差不多，可以准备谢幕了（雾）' // 30
  ];
  private static TIME_TO_INDEX: number[][] = [
    [0, 2, 5, 7, 8, 9, 10, 11, 12, 13, 14, 18, 21, 22, 23, 24, 25, 26, 27, 28], // 半夜: 0~4点
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 27, 28, 29], // 早晨: 5~9点
    [0, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 20, 22, 23, 24, 25, 27, 28], // 白天: 10~18点
    [0, 5, 7, 8, 9, 10, 11, 12, 13, 14, 18, 22, 23, 24, 25, 27, 28, 30], // 晚上: 19~24点
  ]
  private static millisecondsInADay = 86400000;
  private static defaultTimestamp = '1000000000'; // 用于没有签到记录时的Unix时间戳

  static getTodayDate(): number { // 保留年、月、日，忽略时、分、秒
    const date = new Date();
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
  }

  static timeSinceLastCheckIn(): number {
    const previousTime = Number(UnifiedPreferences.getSync(LAST_DAY_KEY, CheckInTools.defaultTimestamp));
    const currentTime = CheckInTools.getTodayDate();
    return currentTime - previousTime;
  }

  static getRandomContent(): string {
    const randomItem = (list: number[]) => list[Math.floor(Math.random() * list.length)];
    const hour = new Date().getHours();
    if (hour < 5) {
      return CheckInTools.CHECK_IN_CONTENT_LIST[randomItem(CheckInTools.TIME_TO_INDEX[0])];
    } else if (hour < 10) {
      return CheckInTools.CHECK_IN_CONTENT_LIST[randomItem(CheckInTools.TIME_TO_INDEX[1])];
    } else if (hour < 19) {
      return CheckInTools.CHECK_IN_CONTENT_LIST[randomItem(CheckInTools.TIME_TO_INDEX[2])];
    } else {
      return CheckInTools.CHECK_IN_CONTENT_LIST[randomItem(CheckInTools.TIME_TO_INDEX[3])];
    }
  }

  static loadCheckInOnStartup(): [number, number, boolean, string] {
    const checkInTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0'));
    const timeSinceLastCheckIn = CheckInTools.timeSinceLastCheckIn();
    const checkInConsecutive = timeSinceLastCheckIn <= CheckInTools.millisecondsInADay
      ? Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0')) : 0; // 超过1天未签到就把“连续签到”计数归零
    const checkedInToday = timeSinceLastCheckIn === 0;
    const checkInContent = UnifiedPreferences.getSync(CONTENT_KEY, '') as string;
    return [checkInTotal, checkInConsecutive, checkedInToday, checkInContent];
  }

  static doCheckIn(): [number, number, string] {

    // 签到次数加1，判断是否连续
    const newTotal = Number(UnifiedPreferences.getSync(TOTAL_DAYS_KEY, '0')) + 1;
    let newConsecutive = Number(UnifiedPreferences.getSync(CONSECUTIVE_DAYS_KEY, '0'));
    if (CheckInTools.timeSinceLastCheckIn() === CheckInTools.millisecondsInADay) {
      newConsecutive += 1;
    } else {
      newConsecutive = 1;
    }
    const randomContent = CheckInTools.getRandomContent();

    // 写入首选项并落盘
    UnifiedPreferences.putSync(LAST_DAY_KEY, CheckInTools.getTodayDate());
    UnifiedPreferences.putSync(TOTAL_DAYS_KEY, newTotal);
    UnifiedPreferences.putSync(CONSECUTIVE_DAYS_KEY, newConsecutive);
    UnifiedPreferences.putSync(CONTENT_KEY, randomContent);

    return [newTotal, newConsecutive, randomContent];
  }
}
