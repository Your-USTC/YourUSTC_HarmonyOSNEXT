
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 你的科大 for HarmonyOS NEXT

</div>

## 注意事项

克隆/下载本仓库后，请先将根目录 `build-profile.json5.bak` 文件名中的 `.bak` 扩展名去除，方可在 DevEco Studio 中正确打开。

## 项目结构

```
/entry/src/main/ets/

    /* 应用程序主体 */
    entryability/
        EntryAbility.ets        // 应用程序入口点: 获取日历权限
    pages/
        Index.ets               // 首页 (主程序)
        Webview.ets             // 浏览器页面
        Schedule.ets            // 本地课表页面
    utils/
        tools.ets               // 公共工具区
        UnifyPreference.ets     // 全局传递配置信息功能
        CheckIn.ets             // 签到功能
        TimeTable.ets           // [JavaScript] 获取课表功能
        FunctionOrder.ets       // 最近使用功能
    view/
        GridComponent.ets       // 功能组件
        SettingsComponent.ets   // 设置项组件
    constants/
        UserAgent.ets           // Webview UA 参数
        ListDataConstants.ets   // 分区标题表
        GridListDataSources.ets // 分区按钮表
        Links.ets               // 链接表
        SettingsSources.ets     // 设置项表

    /* 课程表卡片 */
    entryformability/
        EntryFormAbility.ets    // 卡片生命周期接口
    class_schedule_daily/
        pages/Class_schedule_dailyCard.ets  // 卡片主程序
        view/CardListComponent.ets          // 卡片框架
        viewmodel/CardListParameter.ets     // 卡片构造函数
```

## 隐私政策

https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802923490693635520
