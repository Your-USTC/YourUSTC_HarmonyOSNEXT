
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 你的科大 <font size="4">for HarmonyOS NEXT</font>

[![Stars](https://img.shields.io/github/stars/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT)
&nbsp;&nbsp;
[![Forks](https://img.shields.io/github/forks/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT)

[![Release](https://img.shields.io/github/v/release/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/releases/latest)
&nbsp;&nbsp;
[![Downloads](https://img.shields.io/github/downloads/Your-USTC/YourUSTC_HarmonyOSNEXT/total?style=social&logo=github)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/releases/latest)

![Repo size](https://img.shields.io/github/repo-size/Your-USTC/YourUSTC_HarmonyOSNEXT)
&nbsp;&nbsp;
![Top lang](https://img.shields.io/badge/ArkTS-blue)

### 中国科大一站式导航 · 开启你的智慧校园

#### [用户协议](https://gnu.ac.cn/licenses/gpl-3.0-standalone.html)&nbsp;&nbsp;|&nbsp;&nbsp;[隐私政策](https://gnu.ac.cn/licenses/gpl-3.0-standalone.html)

</div>

## 功能介绍

## 软件截图

<image src="resources/light_1.png" width="160"/>
<image src="resources/dark_2.png" width="160"/>
<image src="resources/light_3.png" width="160"/>
<image src="resources/light_4.png" width="160"/>

## 开发准备

## 项目结构

<details>
<summary>查看</summary>

```
AppScope/                                   // 应用信息、全局资源

entry/src/main/
│
├── module.json5                            // 主程序配置信息
│
├── resources/                              // 主程序资源目录
│   └── base/profile/                       // 页面、卡片、快捷方式配置
│
└── ets/                                    // 源代码目录
    │
    │   // 应用程序
    │
    ├── entryability/
    │   └── EntryAbility.ets                // 应用程序入口点
    │
    ├── pages/
    │   ├── Index.ets                       // 应用程序主体框架
    │   ├── Webview.ets                     // 浏览器页面
    │   ├── Schedule.ets                    // 本地课表页面
    │   ├── ExamDetail.ets                  // 本地考试信息页面
    │   ├── GetSchedule.ets                 // 同步在线课表、考试页面
    │   ├── Help.ets                        // 帮助页面
    │   ├── About.ets                       // 关于页面
    │   └── FaultOccurred.ets               // 恢复模式页面
    │
    ├── constants/
    │   ├── GridListDataSources.ets         // 功能页按钮表
    │   ├── GridListIcons.ets               // 功能页图标表
    │   ├── Links.ets                       // 功能页链接表
    │   ├── ListDataConstants.ets           // 功能页分区标题表
    │   ├── SettingsSources.ets             // 设置页选项表
    │   └── UserAgent.ets                   // Webview UA 参数
    │
    ├── utils/
    │   ├── CheckIn.ets                     // 签到功能
    │   ├── ExamManager.ets                 // 考试信息管理类
    │   ├── FunctionOrder.ets               // 最近使用功能
    │   ├── TimeTable.ets                   // 课表管理类、在线课表获取脚本
    │   ├── tools.ets                       // 公共工具区
    │   └── UnifyPreference.ets             // 全局共享首选项读写功能
    │
    ├── view/
    │   ├── GridComponent.ets               // 功能组件
    │   └── SettingsComponent.ets           // 设置项组件
    │
    │   // 服务卡片
    │
    ├── entryformability/
    │   └── EntryFormAbility.ets            // 卡片生命周期接口
    │
    └── class_schedule_daily/
        ├── pages/
        │   └── Class_schedule_dailyCard.ets// 卡片主程序
        ├── view/
        │   └── CardListComponent.ets       // 卡片框架
        └── viewmodel/
            └── CardListParameter.ets       // 卡片构造函数
```

</details>

## 开源许可

[<image src="https://gnu.ac.cn/graphics/gplv3-or-later.svg" height="18"/> **GNU General Public License v3.0 (GPLv3)**](LICENSE)

YourUSTC  Copyright (C) 2025  YourUSTC Developer Team
