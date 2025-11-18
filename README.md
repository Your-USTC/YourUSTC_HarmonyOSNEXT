
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 你的科大 <font size="4">for HarmonyOS NEXT</font>

[![Stars](https://img.shields.io/github/stars/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT)
&nbsp;
[![Forks](https://img.shields.io/github/forks/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT)

[![Release](https://img.shields.io/github/v/release/Your-USTC/YourUSTC_HarmonyOSNEXT)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/releases/latest)
&nbsp;
[![Downloads](https://img.shields.io/github/downloads/Your-USTC/YourUSTC_HarmonyOSNEXT/total)](https://github.com/Your-USTC/YourUSTC_HarmonyOSNEXT/releases/latest)

![Repo size](https://img.shields.io/github/repo-size/Your-USTC/YourUSTC_HarmonyOSNEXT)
&nbsp;
![ArkTS](https://img.shields.io/badge/ArkTS-blue)

### 中国科大一站式导航 · 开启你的智慧校园

#### [用户协议](https://gnu.ac.cn/licenses/gpl-3.0-standalone.html)&nbsp;&nbsp;|&nbsp;&nbsp;[隐私政策](https://gnu.ac.cn/licenses/gpl-3.0-standalone.html)

</div>

## 功能介绍

### 课程与考试信息管理

- [x] 从教务系统半自动提取课表/考试信息，并导入到本地
- [x] 在首页显示今日与明日课程、考试倒计时信息
- [x] 点击课程/考试能显示详情
- [x] 可手动添加、修改、删除课程/考试，可编辑内容较全面
- [x] 可将课程/考试导入系统日历，设置提醒时间，也可清除本 App 创建的所有日程
- [x] 针对可能的错误和崩溃启用恢复模式

### 校园常用功能链接

- [x] 在功能页分类显示链接，并用内嵌浏览器打开
- [x] 显示“最近使用”，并可清空/定制显示数量
- [x] 内嵌浏览器支持切换 UA、前进后退、上传/下载文件、释放缓存、在系统浏览器中打开等功能

### 用户界面 (UI) 和其它

- [x] 鸿蒙多端设备（手机/平板/PC）基本适配
- [x] 浅色/深色模式良好适配（包括网页）
- [x] 定制首页功能显示情况
- [ ] 在服务卡片中展示“你的课表”和“考试信息”……

## 软件截图

<image src="resources/light_1.png" width="160"/><image src="resources/dark_2.png" width="160"/><image src="resources/light_3.png" width="160"/><image src="resources/light_4.png" width="160"/>

## 开发指南

### 环境构建

1. 系统要求：Windows ≥ 10 (x64)
2. 开发环境：DevEco Studio 6.0.0
3. 克隆本仓库
4. 将 `build-profile.json5.bak` 重命名为 `build-profile.json5`
5. 在 DevEco Studio 中打开项目，即可在模拟器和 HarmonyOS NEXT 设备（需要自行配置签名）上运行

### 项目结构

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
