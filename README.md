
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 你的科大 for HarmonyOS NEXT

</div>

## 注意事项

克隆/下载本仓库后，请先将根目录 `build-profile.json5.bak` 文件名中的 `.bak` 扩展名去除，方可在 DevEco Studio 中正确构建。

## 项目结构

```
entry/src/main/ets/
├── class_schedule_daily
│   ├── pages
│   │   └── Class_schedule_dailyCard.ets    // 卡片主程序
│   ├── view
│   │   └── CardListComponent.ets           // 卡片框架
│   └── viewmodel
│       └── CardListParameter.ets           // 卡片构造函数
├── constants
│   ├── GridListDataSources.ets             // 功能页按钮表
│   ├── GridListIcons.ets                   // 功能页图标表
│   ├── Links.ets                           // 功能页链接表
│   ├── ListDataConstants.ets               // 功能页分区标题表
│   ├── SettingsSources.ets                 // 设置项表
│   └── UserAgent.ets                       // Webview UA 参数
├── entryability
│   └── EntryAbility.ets                    // 应用程序入口点: 获取日历权限
├── entrybackupability
│   └── EntryBackupAbility.ets
├── entryformability
│   └── EntryFormAbility.ets                // 卡片生命周期接口
├── pages
│   ├── About.ets                           // 关于页面
│   ├── ExamDetail.ets                      // 本地考试信息页面
│   ├── FaultOccurred.ets                   // 
│   ├── GetSchedule.ets                     // 
│   ├── Help.ets                            // 帮助页面
│   ├── Index.ets                           // 首页 (主程序)
│   ├── Schedule.ets                        // 本地课表页面
│   └── Webview.ets                         // 浏览器页面
├── utils
│   ├── CheckIn.ets                         // 签到功能
│   ├── ExamManager.ets                     // 考试信息管理类
│   ├── FunctionOrder.ets                   // 最近使用功能
│   ├── TimeTable.ets                       // 课表管理类与在线课表获取脚本
│   ├── UnifyPreference.ets                 // 全局共享首选项读写功能
│   └── tools.ets                           // 公共工具区
├── view
│   ├── GridComponent.ets                   // 功能组件
│   └── SettingsComponent.ets               // 设置项组件
entry/src/main/resources                    // 应用静态资源目录
```

## 隐私政策

https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802923490693635520

## 相关权限

1. ohos.permission.INTERNET
2. ohos.permission.GET_NETWORK_INFO
3. ohos.permission.WRITE_CALENDAR
4. ohos.permission.READ_CALENDAR