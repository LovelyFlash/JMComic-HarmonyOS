# PicaComic HarmonyOS

一款支持多源的漫画阅读器鸿蒙原生应用，基于 ArkTS/ArkUI 开发，支持 HarmonyOS NEXT (API 26+)。

## 功能特性

- **多源漫画浏览**: NHentai、Hitomi、Picacg、E-Hentai、JM、HT
- **在线阅读**: 多种翻页模式
- **下载收藏**: 批量下载和收藏管理
- **阅读历史**: 自动记录阅读进度
- **深色模式**: 支持跟随系统切换
- **主题颜色**: 9 种预设颜色
- **国际化**: 中文/英文
- **搜索功能**: 多源搜索
- **图片质量**: 低/中/高/原始
- **字体大小**: 12-24sp
- **书签功能**: 阅读器书签
- **自动更新**: JM/HT 域名自动刷新

## 快速开始

### 环境要求
- DevEco Studio 26.0+
- HarmonyOS NEXT SDK (API 26+)

### 构建步骤
```bash
# 1. 打开项目
# 在 DevEco Studio 中打开 ohos/ 目录

# 2. 配置签名
# File > Project Structure > Signing Configs

# 3. 构建 HAP
cd ohos
$env:DEVECO_SDK_HOME = "F:\DevEco Studio\sdk"
F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat assembleHap --mode module -p module=entry -p product=default --no-daemon
```

### 安装测试
```bash
# 安装到设备
F:\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe install entry-default-unsigned.hap

# 启动应用
hdc shell aa start -a EntryAbility -b com.picacomic.harmony
```

## 项目结构

```
ohos/
├── entry/src/main/ets/
│   ├── common/          -- 通用工具
│   ├── data/api/        -- API 客户端
│   ├── data/database/   -- SQLite
│   ├── viewmodel/       -- 状态管理
│   ├── components/      -- UI 组件
│   ├── pages/           -- 页面
│   ├── plugin/          -- 原生插件
│   └── entryability/    -- 入口
```

## 漫画源配置

| 漫画源 | 域名 | 更新方式 |
|--------|------|---------|
| NHentai | nhentai.net | 固定 |
| Hitomi | hitomi.la | 固定 |
| Picacg | api.picacg.com | 固定 |
| EHentai | e-hentai.org | 固定 |
| JM | 动态域名 | 自动获取 |
| HT | wnacg.com | 手动更新 |

## 主题

支持 9 种主题颜色：蓝、紫、粉、红、橙、黄、绿、青、靛蓝

支持深色模式：跟随系统 / 禁用 / 启用

## 许可证

MIT License

## 致谢

- [PicaComic](https://github.com/wgh136/PicaComic) - 原 Flutter 项目
- [HarmonyOS SDK](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5) - 鸿蒙开发文档