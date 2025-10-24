
<div align="center">

# <image src="AppScope/resources/base/media/icon_round.png" height="28" width="28"/> 你的科大 for HarmonyOS NEXT

</div>

## 注意事项

克隆/下载本仓库后，请先将根目录 `build-profile.json5.bak` 文件名中的 `.bak` 扩展名去除，方可在 DevEco Studio 中正确打开。

## 项目结构

```
/entry/src/main/ets/
    constants/
        CommonConstants.ets     // 公共常量区
        GridListDataSources.ets // 分区和按钮表
        Links.ets               // 链接表
        ListDataConstants.ets   // 分区表
        SettingsSources.ets     // 设置项表
        stringForGrid.ets       // 按钮信息显示
        UserAgent.ets           // Webview UA 参数
    pages/
        Index.ets               // 首页 (主程序)
        Webview.ets             // 浏览器页面
    utils/
        CheckIn.ets             // 签到功能
        FunctionOrder.ets       // 最近使用功能
        TimeTable.ets           // [JavaScript] 获取课表
        tools.ets               // 公共工具区
    view/
        GridComponent.ets       // 功能组件
        SettingsComponent.ets   // 设置项组件
```

## 隐私政策

https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1802923490693635520
