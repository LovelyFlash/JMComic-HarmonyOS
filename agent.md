# PicaComic HarmonyOS - Agent 开发指南

## 项目概述

PicaComic 鸿蒙版是一款基于 ArkTS/ArkUI 开发的多源漫画阅读器应用，支持 HarmonyOS NEXT (API 26+)。

## 项目架构

```
ohos/
├── entry/src/main/ets/
│   ├── common/          -- 通用工具 (Logger, ThemeManager, Constants, Translations)
│   ├── data/
│   │   ├── api/         -- API 客户端 (Network, NhentaiApi, HitomiApi, PicacgApi, EhentaiApi, JmApi, HtcomicApi)
│   │   ├── database/    -- SQLite 数据库
│   │   └── preferences/ -- SharedPreferences
│   ├── viewmodel/       -- 状态管理 (AppData, HistoryManager, FavoritesManager, DownloadManager)
│   ├── components/      -- UI 组件 (ComicTile, ComicGrid, LoadingView, ErrorView, SearchBar, FloatingTabBar)
│   ├── pages/           -- 页面 (MainPage, ExplorePage, SearchPage, HistoryPage, FavoritesPage, DownloadPage, ComicDetailPage, reader/)
│   ├── pages/settings/  -- 设置页 (SettingsPage, AboutPage, 6个漫画源设置)
│   ├── pages/nhentai/   -- NHentai 首页
│   ├── pages/hitomi/    -- Hitomi 首页
│   ├── pages/picacg/    -- Picacg 首页
│   ├── pages/ehentai/   -- EHentai 首页
│   ├── pages/jm/        -- JM 首页
│   ├── pages/htcomic/   -- HT 首页
│   ├── plugin/          -- 原生插件 (Device, Battery, Widget, Decor, Continuation, UrlLauncher, Share, FilePicker, Download, Volume, Screenshot, KeepScreenOn, Proxy, FullScreen)
│   └── entryability/    -- 入口 Ability
```

## 开发规范

### ArkTS 编码规范
1. **禁止 `globalThis`**: 使用模块级变量代替
2. **禁止 `any`/`unknown`**: 必须显式声明类型
3. **禁止对象字面量类型**: 使用 class 或 interface
4. **Import 语句**: 必须在文件顶部
5. **类型断言**: 使用 `as` 而非 `!`

### 组件规范
1. **使用 `@Component` 装饰器**: 定义组件
2. **使用 `@StorageLink`**: 响应全局状态变化
3. **使用 `@Prop`**: 传递数据
4. **使用 `@State`**: 管理组件状态
5. **图片加载**: 必须指定 `alt` 占位图

### API 调用规范
1. **使用 `@ohos.net.http`**: HTTP 请求
2. **使用 `@ohos.data.relationalStore`**: SQLite 数据库
3. **使用 `@ohos.data.preferences`**: 键值存储
4. **异步操作**: 使用 `async/await`
5. **错误处理**: 必须 try-catch

## 构建流程

### 开发环境
- DevEco Studio: 26.0.0.821
- HarmonyOS SDK: 26.0.0 (API 26)
- Node.js: 内置

### 构建命令
```bash
# 设置环境变量
$env:DEVECO_SDK_HOME = "F:\DevEco Studio\sdk"
$env:HOS_SDK_HOME = "F:\DevEco Studio\sdk\default\openharmony"

# 构建 HAP
cd ohos
F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat assembleHap --mode module -p module=entry -p product=default --no-daemon
```

### 调试工具
```bash
# 安装 HAP
F:\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe install entry-default-unsigned.hap

# 启动应用
hdc shell aa start -a EntryAbility -b com.picacomic.harmony

# 查看日志
hdc shell hilog | grep pica_comic

# 强制停止
hdc shell aa force-stop com.picacomic.harmony
```

## 漫画源 API 配置

### NHentai
- 主域名: `https://nhentai.net`
- API: `/api/galleries?page={page}`
- 搜索: `/api/galleries/search?query={keyword}`

### Hitomi
- 主域名: `https://hitomi.la`
- 列表: `/n/{page}.json`
- 详情: `/galleries/{id}.js`

### Picacg
- 主域名: `https://api.picacg.com`
- 列表: `/comics?page={page}&sort={sort}`
- 搜索: `/comics/advanced-search?page={page}&q={keyword}`

### EHentai
- 主域名: `https://e-hentai.org`
- 列表: `/?page={page}`
- 搜索: `/?f_search={keyword}`

### JM (禁漫)
- 主域名: 动态域名 (自动获取)
- API: `/latest`, `/search`, `/album`
- CDN: 4个分流节点

### HT (绅士漫画)
- 主域名: `https://www.wnacg.com`
- 列表: `/albums-index-page-{page}.html`
- 搜索: `/search?q={keyword}`

## 主题系统

### 颜色定义
```typescript
// 亮色主题
PRIMARY: '#007AFF'
BACKGROUND: '#FFFFFF'
TEXT_PRIMARY: '#000000DE'

// 暗色主题
PRIMARY: '#0A84FF'
BACKGROUND: '#000000'
TEXT_PRIMARY: '#FFFFFFDE'
```

### 使用方式
```typescript
import { ThemeManager } from '../common/ThemeManager';

@Component
struct MyComponent {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  
  build() {
    Column() {
      Text('Hello')
        .fontColor(ThemeManager.colors.TEXT_PRIMARY)
        .backgroundColor(ThemeManager.colors.BACKGROUND)
    }
  }
}
```

## 常见问题

### Q: 如何添加新的漫画源？
1. 在 `data/api/` 下创建新的 API 客户端
2. 在 `pages/` 下创建对应的首页
3. 在 `pages/settings/` 下创建设置页
4. 更新 `main_pages.json` 路由配置

### Q: 如何修改主题颜色？
编辑 `common/ThemeManager.ets` 中的 `LightColors` 和 `DarkColors` 类。

### Q: 如何添加新的设置项？
1. 在 `common/Constants.ets` 中添加设置键
2. 在 `pages/settings/SettingsPage.ets` 中添加 UI
3. 使用 `Settings.getBool/setBool` 读写设置