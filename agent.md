# JMComic HarmonyOS - Agent 开发指南

## 项目概述

禁漫天堂（JMComic）鸿蒙原生漫画阅读器，基于 ArkTS/ArkUI，HarmonyOS NEXT (API 26+)。
单漫画源（JM），包名 `com.jmcomic.harmony`，无第三方依赖。

**当前状态**：
- master = **v1.0.10**（versionCode 11，2026-10-10 发布）；发版基线在 master，最新 Release 见 GitHub `releases/tag/v1.0.10`
- 版本三处需同步：`AppScope/app.json5`（versionCode/versionName）、`Constants.APP_VERSION`（关于页/设置页动态显示）、`Changelog.ets`（应用内更新日志，倒序新增条目）
- `feature/compat-sdk20` 分支：`compatibleSdkVersion` 降至 `6.0.0(20)` + 新 API 版本守卫与低版本降级（0 编译兼容告警，真机冒烟通过），**已推送、暂未合并且暂不发版**
- v1.0.10 落地的主线能力：发现页 NavDestination 化（标题栏胶囊分段切换 + .menus() 刷新按钮 + STACK/GRADUAL_BLUR 沉浸材质）、全部二级页面标题背景透明 + expandSafeArea 补齐、阅读器工具栏按钮官方规格化（40vp 圆形 + content_on_media）、设置/阅读设置/关于页 STACK 标题栏、异常捕获与 syscap 告警清理
- v1.0.9 落地的主线能力：章节真实下载（DownloadManager 队列/后台任务/页级进度/暂停重试/删除清理）、离线阅读（pages.json 页列表持久化 + 本地优先 + file:// 封面修复）、详情缓存秒开（DetailCache）、官方 `.title()`/UIContext 迁移与冗余组件（LoadingView/AppTopBar/NavTitleBar）清理
- v1.0.7 落地的主线能力：搜索支持漫画 ID、详情页信息栏（ID/作者/日期按钮化标签、长名换行）、标签 ChipTokens 统一、关于页更新日志、Logger 级别控制与全局崩溃捕获（EntryAbility errorManager）

**分支模型**：`master` 主线（发布基线）；`feature/*` 功能分支；发版流程 = 内容提交 + `chore(release): vX`（**只含 app.json5**）+ 轻量 tag + `gh release create` 上传 signed/unsigned 双包（README「版本发布流程」有完整步骤）。

**参考基准（只读，本机路径）**：`D:\desktop\JMComic-Crawler-Python-master`
- `src/jmcomic/jm_toolkit.py` — `JmCryptoTool`（token / decode_resp_data / md5hex）、`get_num` / `decode_and_save`（图片分段与反打乱）
- `src/jmcomic/jm_config.py` — 密钥与版本参数（APP_TOKEN_SECRET / APP_TOKEN_SECRET_2 / APP_DATA_SECRET / API_DOMAIN_SERVER_SECRET / APP_VERSION）
- `src/jmcomic/jm_client_impl.py` — `fetch_scramble_id`、`req_api_domain_server`
- 一致性对照：PicaComic `lib/foundation/image_loader/image_recombine.dart`、jmcomic-downloader `download_manager.rs::stitch_img`

## 项目架构

```
ohos/entry/src/main/ets/
├── common/
│   ├── Constants.ets      -- ApiConstants（JM 密钥/域名/UA）、SettingsKeys、DatabaseConstants
│   ├── JmImage.ets        -- JM 图片管线：请求头、魔数嗅探、分段数、decode、recombine（反打乱）
│   ├── Network.ets        -- HTTP 封装：get/getWithStatus/getBytes/getBytesViaDownload/post
│   ├── Logger.ets         -- hilog 封装（LogLevel 级别控制、describe/exception、崩溃捕获；TAG 过滤：JmApi/JmImage/ReaderImage/ReaderPage/Network/Database）
│   ├── ThemeManager.ets   -- 深色策略 + 主题色（UI 颜色一律走 $r 资源令牌）
│   ├── Translations.ets   -- 中英文案
│   ├── ReadingConfig.ets  -- 阅读配置
│   ├── NavUtil.ets        -- 导航工具
│   ├── Changelog.ets      -- 应用内更新日志数据（ReleaseNote 倒序，关于页展示）
│   ├── ToastUtil.ets      -- Toast 统一封装（UIContext.getPromptAction）
│   └── ArrayDataSource.ets-- LazyForEach 数据源
├── data/
│   ├── api/JmApi.ets      -- 禁漫 API 客户端（token/data 加解密对照 jm_toolkit.py）
│   ├── database/Database.ets   -- SQLite（pica_comic.db: history/favorites/downloads）
│   ├── download/DownloadManager.ets -- 章节下载队列（后台任务/页级进度/暂停重试/离线页列表）
│   ├── cache/DetailCache.ets -- 已下载漫画详情/封面/评论本地缓存（详情页秒开）
│   ├── model/             -- Comic, Chapter, Comment, ComicPageData, ReaderParam
│   └── preferences/Settings.ets -- 键值存储
├── viewmodel/AppData.ets  -- 全局状态
├── components/
│   ├── ReaderImage.ets    -- 阅读器图片（下载→解码→反打乱→LRU 缓存，失败可重试）
│   ├── NetworkImage.ets   -- 普通网络图片（封面等，无需反打乱）
│   ├── ComicTile/ComicGrid/AppIcon
│   └── SettingItem/SettingSection/SettingSwitch/SettingSelect/SettingCommon/SettingCheckItem/SettingInfoItem
├── pages/
│   ├── MainPage.ets       -- 底部 Tab 主页
│   ├── LaunchPage.ets     -- 启动页（首帧 + 历史数据预热 + 600ms 最短展示，main_pages 首位）
│   ├── DiscoverPage / SearchPage / PreSearchPage / CategoryPage / JmCategoryPage
│   ├── JmWeekPage / JmPromotePage / ComicDetailPage / CommentsPage
│   ├── HistoryPage / FollowPage / FavoritesContent / DownloadPage（真实下载：聚合进度/暂停继续重试/删除清理，见「下载功能」节）
│   ├── MePage / AccountsPage
│   ├── reader/ReaderPage.ets  -- 阅读器（6 阅读模式：LTR/RTL/TTB/连续滚动/双页/双页反向；手势缩放；连续滚动锚点稳定；push-first 自取首章 + 三模式 LazyForEach 惰性构建；阅读器内状态栏全程隐藏）
│   └── settings/          -- SettingsPage(List+Select), ReadingSettings, JmSettings, AboutPage（内置标题栏 .title().hideTitleBar(false)；AboutPage 含「更新日志」分区，数据源 Changelog.ets）
└── entryability/EntryAbility.ets
```

## 开发规范

### ArkTS 编码规范
1. **禁止 `globalThis`**: 使用模块级变量代替
2. **禁止 `any`/`unknown`**: 必须显式声明类型
3. **禁止对象字面量类型**: 使用 class 或 interface
4. **Import 语句**: 必须在文件顶部
5. **类型断言**: 使用 `as` 而非 `!`

### 主题与颜色规范（深色模式）
1. **UI 颜色一律 `$r('app.color.*')` 资源令牌**（base/dark 同名自动切换），禁止硬编码色值（阅读器黑底白字、图片遮罩等固定色除外）
2. **品牌色用 `@StorageProp('themeColor') themeColor: string = '#2563EB'`**，绑定 `this.themeColor`；ThemeManager 的颜色 getter 已删除，勿恢复
3. **禁止为颜色变化挂状态**：不要用 `@StorageLink('isDarkMode')`/`themeVersion` 触发重绘，资源切换无需任何逻辑
4. 系统 API（`setWindowBackgroundColor` 等）需要具体色值 → `ThemeManager.windowBackground`（唯一合法取值口）
5. 新增颜色必须在 `base/element/color.json` 与 `dark/element/color.json` 同时定义
6. **默认主题色集中于 `Constants.DEFAULT_THEME_COLOR`**：`@StorageProp('themeColor')` 等 string 默认值无法用 `$r`，各页禁止硬编码 `'#2563EB'`
7. **阅读器固定色**（黑白不随主题，独立令牌）：`reader_bg` / `text_on_reader` / `reader_text_secondary` / `reader_overlay` / `reader_overlay_button` / `reader_sidebar_track` / `reader_slider_track` / `media_scrim` / `content_on_media`

### 组件规范
1. **使用 `@Component` 装饰器**: V1 状态管理（@State/@Prop/@StorageLink 等），禁止与 V2 混用
2. **图片加载**: 必须指定占位/错误态
3. **ForEach/LazyForEach**: 必须提供稳定 key

### API 调用规范
1. **HTTP**: 统一走 `Network` 封装（@ohos.net.http），文本用 `get`/`post`，二进制用 `getBytes`（ARRAY_BUFFER）
2. **SQLite**: @ohos.data.relationalStore，见 `Database.ets`
3. **Preferences**: @ohos.data.preferences，见 `Settings.ets`
4. **异步操作**: async/await + try-catch；Promise 结果必须 await 后再取属性
5. **图片**: Image Kit（@kit.ImageKit），解码显式传 `desiredPixelFormat: RGBA_8888`

## 主题与深色模式适配

颜色令牌定义于 `resources/base/element/color.json`（浅色）与 `resources/dark/element/color.json`（深色），深浅切换由系统资源限定词目录自动完成，**组件内不做任何模式判断**。

| 令牌 | Light | Dark | 用途 |
|---|---|---|---|
| `bg_page` | #F8F9FA | #111827 | 页面底层（Level 0） |
| `bg_surface` | #FFFFFF | #1F2937 | 卡片/列表容器（Level 1） |
| `bg_elevated` | #FFFFFF | #374151 | 浮层/更高层级（Level 2，自定义弹窗用；系统弹层自适配） |
| `bg_fill` | #F3F4F6 | #374151 | chip/输入框/行填充 |
| `text_primary` | #1A1A1A | #F3F4F6 | 正文 |
| `text_secondary` | #666666 | #D1D5DB | 次要文字 |
| `text_tertiary` | #999999 | #9CA3AF | 提示/禁用 |
| `text_on_brand` | #FFFFFF | #FFFFFF | 彩色底（品牌色/危险色）上的前景白 |
| `divider` | #E5E7EB | #374151 | 分割线/边框 |
| `brand_primary` | #2563EB | #3B82F6 | 默认品牌色（仅种子值，运行时用 themeColor） |
| `danger` | #FF3B30 | #FF453A | 错误态 |
| `shadow` | #33000000 | 透明 | 投影（深色下按设计规范去除） |
| `start_window_background` | #F8F9FA | #111827 | 启动页 |

- **深色策略**：`ThemeManager.setDarkModePolicy('system'|'enabled'|'disabled')` → `setColorMode(NOT_SET|DARK|LIGHT)`；策略存 `AppStorage('darkModePolicy')` 供设置页刷新
- **品牌色**：`ThemeManager.setThemeColor` 持久化 + `AppStorage('themeColor')`；组件用 `@StorageProp('themeColor')` 响应
- **状态栏**：沉浸式下按有效深浅状态设 `statusBarContentColor`（EntryAbility.systemBarNotifier），窗口实例缓存
- **遗漏清单**（改动颜色后走查）：分割线、图标 fontColor、投影、弹窗内容、Toast、TabBar、Loading

## 构建流程

### 构建命令（devecocli，在 ohos/ 目录下执行）

```powershell
devecocli build                    # 构建 HAP（约 6 分钟）
devecocli run                      # 构建 + 安装 + 启动
devecocli run --skip-build         # 跳过构建，部署已有产物
devecocli run --uninstall          # 先卸载再装（解决签名不一致）
devecocli device list              # 查看设备
devecocli build clean              # 清理构建产物
```

### 快速编译验证（不安装，仅查编译错误；在 ohos/ 目录下）

```powershell
$env:PATH = "D:\DevEco Studio\tools\node;" + $env:PATH
$env:DEVECO_SDK_HOME = "D:\DevEco Studio\sdk"
& "D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default --no-daemon
```

仅既有 deprecated/showToast/2in1 警告可忽略；`ArkTS:ERROR` 为真实错误。增量编译约 15s。

### 发版前全量验证（仓库根执行，PS 5.1）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-verify.ps1
```
五步：文件清单 → 编码损坏（U+FFFD）→ ArkTS 合规 → 设计令牌 → hvigor 构建；全绿才可打包上传 Release。

### 调试工具

```powershell
devecocli log --keyword JmImage --from 5m       # 图片管线日志（recombine ok/skip、non-image bytes）
devecocli log --keyword ReaderImage --from 5m   # 阅读器图片加载日志（load failed 等）
devecocli log --keyword ReaderPage --from 5m    # 阅读器滚动诊断日志（strip area change / flush pending）
devecocli log --crash --bundle-name com.jmcomic.harmony  # 崩溃日志
devecocli log clear                # 清空 hilog（复现问题前先清）
devecocli ui screenshot --path ./shot.png       # 截图
devecocli ui layout                --format json # UI 树检查
```

注意：真机锁屏时 `devecocli run` 启动会报 10106102，需先解锁屏幕。

## JM API 要点（JmApi.ets）

### 加解密（对照 jm_toolkit.py JmCryptoTool）
- **token**: 普通接口 `md5Hex(time + JM_SECRET)`（APP_TOKEN_SECRET=`185Hcomic3PAPP7R`）；`/chapter_view_template` 必须用 `md5Hex(time + JM_AUTH_KEY)`（APP_TOKEN_SECRET_2=`18comicAPPContent`），混用会 403
- **data 解密**: 响应 `data` 字段为 Base64 密文；key = `md5Hex(time + JM_SECRET)`（APP_DATA_SECRET，time 与请求头一致），AES256-ECB 解密后按 Python `data[:-data[-1]]` 去尾部 padding，再 UTF-8 解码
- **域名密文**: ts 传空串，key = `md5Hex(JM_DOMAIN_SECRET)`（API_DOMAIN_SERVER_SECRET），解密前先去掉头部非 ASCII 字符
- md5Hex 为纯 ArkTS 实现（已与 Python/Node hashlib 逐位对拍验证），AES 用 @ohos.security.cryptoFramework

### 域名策略
1. 内置 API 域名（JM_BUILTIN_API_DOMAINS）
2. 远端域名列表（JM_DOMAIN_URLS，密文解密），24h 自动更新
3. 回退列表（JM_FALLBACK_API_DOMAINS）
图片分流：JM_IMG_URLS 候选 + JM_DEFAULT_IMG_HOST 默认值，可在 JM 设置页切换。

### 主要接口
- `/latest`（最新）、`/search`（搜索）、`/album`（详情+章节）、`/chapter`（章节图片文件名）
- `/hot_tags`（热搜词）、`/week` + `/week/filter`（每周必看）、`/categories`（分类）
- `/login`（登录）、`/favorite`（收藏夹）、`/check_in`（签到）、评论相关
- scramble_id：GET `/chapter_view_template?id={photoId}&...`，正则抓 `var scramble_id = (\d+);`，失败回退 `'220980'`

## JM 图片管线（JmImage.ets + ReaderImage.ets）

```
URL → Network.getBytes(http栈) → 魔数嗅探(looksLikeImage)
    → 失败则 getBytesViaDownload(下载服务栈) → 再嗅探
    → JmImage.decode(RGBA_8888) → JmImage.recombine(反打乱) → Image(PixelMap)
```

- **分段数 getSegmentationNum**: `aid < scrambleId → 0`；`< 268850 → 10`；否则 md5(`aid+文件名去扩展名`) 的**末字符取 ASCII 码（ord）**，`< 421926 → ord%10*2+2`，否则 `ord%8*2+2`
- **反打乱 recombine**: 对齐 `decode_and_save` / `_segmentationPicture` / `stitch_img`——源图按 `floor(h/num)` 切段，末段附带 `h%num` 余数行；目标图从末段开始**整段逆序**贴合，**段内不旋转**；全量 `readAllPixelsToBuffer` 后 `createPixelMapFromPixels` 重建（显式 `srcPixelFormat: RGBA_8888`）
- **注意**: `createPixelMap()` 默认 `editable: false`，`writePixels` 会失败 —— 不要对解码产物原地写像素，必须重建
- **缓存**: ReaderImage 内置 LRU（12 张 PixelMap，按 URL）
- **GIF**: 跳过反打乱直接 `Image(url)` 显示

## 阅读器工程要点（ReaderPage.ets + ReaderImage.ets）

### 状态栏（Q2 全程隐藏）
- **全程隐藏**：阅读器内状态栏从进入直到退出**始终隐藏**——打开工具栏/半模态**不再恢复**状态栏。原因：状态栏恢复 → `avoidAreaChange` 回写 `topAvoidHeight` → `@StorageProp` 触发整棵树重渲染（Swiper `.index`/`.scale` 等属性重挂），图片肉眼可见错位。`@Watch('onOverlayChanged')` 与 `lastTopAvoid` 缓存已删除；`setStatusBarVisible` 仅两处调用（进入延时隐藏、退出恢复），世代号 `statusBarGen` 防乱序
- **进入/退出**：`aboutToAppear` 延后 `ENTRY_BAR_HIDE_DELAY=400ms` 无条件隐藏（跨过 push 转场，避免前一页避让区在转场中塌陷）；`aboutToDisappear` 无条件 `setStatusBarVisible(true)` 恢复（世代号令挂起的隐藏失效），保证下一页避让就绪
- **工具栏 padding**：直接 `topAvoid + 6`（阅读期间 topAvoid 恒为 0 → 贴顶 6vp；进入后 400ms 窗口内打开则取真实状态栏高，语义正确）。内容链（Stack/Scroll/List）高度一律 `100%`、**不读 topAvoid/bottomAvoid** → 避让切换不影响容器高度（topAvoid 仅工具栏 padding、bottomAvoid 仅工具栏底条/设置页使用）
- 沉浸式布局 `setWindowLayoutFullScreen(true)` 仍开启（内容延伸至系统栏区域，靠 `expandSafeArea` + `topAvoidHeight`/`bottomAvoidHeight` padding 避让，整链写法见下节）
- API 前置条件：`setSpecificSystemBarEnabled(name, enable, animate?)` 需全屏布局 + 主窗口（`SpecificSystemBar = 'status' | 'navigation' | 'navigationIndicator'`），底部手势条用 `'navigationIndicator'`；批量版 `setWindowSystemBarEnable(['navigation'])`
- 避让高度监听：`avoidAreaChange` 事件 → `EntryAbility.updateAvoidAreas`（状态栏隐藏/恢复也会触发该事件回写 topAvoidHeight；也可用 `@Env(SystemProperties.WINDOW_AVOID_AREA)` 响应式方案）

### 连续滚动（strip 模式）— 完整对照参考项目 JMComic-HarmonyOS-main/ImageViewerPage.ets scroll 模式
- **结构**：外层 `Scroll`（pinch 缩放 1x-MAX_ZOOM + 缩放态平移 `scrollable(FREE)` + `maxZoomScale/minZoomScale/enableBouncesZoom/edgeEffect(None)/onDidZoom/onZoomStop`）逐属性对齐参考项目；内层 `List`（`cachedCount(10)` + `nestedScroll PARENT_FIRST×2` + `onScrollIndex` 上报页码）
- **缩放状态**：`stripZoom` 为**普通字段**（`onDidZoom` 逐帧写入不触发重渲），仅 `@State stripZoomed` 越 1.0 阈值翻转驱动 `scrollable/scrollBar` 切换——参考项目 zoomScale 同为普通字段 + `isZoomed` @State；**切勿把 onDidZoom 写进 @State**（pinch 期间整棵内容树按帧重渲会卡顿不跟手）。双击缩放走 `handleDoubleTap` 的 isStrip 分支，跳页/切章/切模式统一 `resetStripZoom()`
- **加载**：ReaderImage 挂载即加载（LazyForEach cachedCount ±10 预建窗口等价参考项目 onAppear 窗口）+ item `onAppear` → `preloadAround` 双向各 10 预热（进场前比例已解码，占位高度不跳变）；**无 active 门控**（旧 `@State stripActiveIdxs` 在滚动中每个缓存窗口边界 crossing 都全量重渲 → 卡顿，已删）
- **锚点**：`stripAnchor(idx)` = 立即 `scrollToIndex(START)` + 80/400ms 两次重校（图片解码前后 item 高度会变化）+ `stripGuard` 期间屏蔽 `onScrollIndex` 上报 + `stripGeneration` 世代校验（对应参考 restoreReadPosition/restoreGuard/chapterGeneration）
- **expandSafeArea**：官方示例7 标准——item 到滚动祖先间**所有直接节点整链设置**（ReaderImage 根+内部各分支、占位 Column、ListItem、内层 List 均 `.expandSafeArea([SYSTEM],[TOP,BOTTOM])`），且**滚动容器必须 `clip(false)`**（内层 List + 外层 Scroll：关闭裁剪，否则 item 的扩展绘制被滚动容器截断 → 避让缺口）。`ReaderImage.expandArea` 默认 true，strip 不再传 false（判空写法 `.expandSafeArea(saTypes(), saEdges())` 仍保留，`([],[])` 官方语义=属性无效）；滚动容器内成链配置后滚动不失效（官方文档第 60 条：缺任一层滚动后可能失效）
- **进度**：`scheduleStripSave`（索引变化 500ms 防抖落盘）/ `flushStripSave`（退出/返回/切章前立即落盘），对应参考 scheduleSavePosition/flushSavePosition
- **列表实现**：LazyForEach + `ArrayDataSource.replaceAll → onDataReloaded`；诊断日志 TAG=`ReaderPage`（`strip first index` / `strip anchor idx=...` / `strip guard released`）

### 进入与切章（push-first + LazyForEach）
- **push-first 进入**：详情页 `startReading` **同步转场**（`NavUtil.push` 传 `images=[]`，不再前置 `await getChapter`——点击后几百毫秒网络等待无反馈是「假死感」主因）；ReaderPage `aboutToAppear` 的 `loadConfig().then` 中 images 为空 → `pendingRestore=true` + `loadChapter(order, startAtEnd, silent=true)` 自取首章，取到图片后再 `restoreProgress()`（续读弹窗依赖 `images.length` 判定，必须在取图后）
- **silent 模式**：不弹「已切换」toast、**不落盘**（`pendingRestore` 期间跳过 `flushStripSave`——进入时无旧章可存，落盘会把已存进度覆盖为第 0 页）；失败置 `@State chapterError` → 内容层「错误+重试」overlay（盖住点按区，点击重取）
- **LazyForEach 惰性构建**：三模式数据源 `singleSource`/`dualSource`/`stripSource`（`ArrayDataSource.replaceAll → onDataReloaded`）。单页/双页 Swiper 原为 ForEach eager 构建——切章/进入一帧内销毁重建整章 N 个页面节点（50-120 页）是掉帧主因；Swiper 官方支持 LazyForEach + `cachedCount(2)` 懒加载（**Repeat 懒加载不支持 V1 状态管理，不可用**）。模式/RTL 切换统一走 `refreshDataSources()` 全量 replaceAll；`active` 窗口门控与 `scale` 绑定为 @Prop/@State 属性级绑定，LazyForEach 节点创建后仍响应状态变化
- **切章反馈**：`loadChapter` 入口**立即** `showSheet=false`（关闭动画不与内容重建叠帧）+ 内容层半透明 `reader_overlay` 遮罩 + LoadingProgress（盖住点按区防误触，工具栏在其上仍可操作）；诊断日志 `fetchMs`/`totalMs`（TAG=ReaderPage）
- **异步安全**：`alive` 标记（`aboutToDisappear` 置 false），取章/续读等异步回调返回时若已退出则丢弃状态写入

## 下载功能与离线阅读（v1.0.9 已实现）

### 架构（`data/download/DownloadManager.ets` + `data/cache/DetailCache.ets`）
- **任务队列与状态机**：`ChapterTask`（class，章节任务：jobId/标题/页数/进度/状态）；状态 `QUEUED/RUNNING/PAUSED/DONE/FAILED`；`pump()` 按并发上限（MAX_ACTIVE）派发，`runChapter()` 执行：取章 → 写 `pages.json` → 逐图下载；暂停 = 中断 + 状态回写，恢复/重试从 progress 续跑；进度存 `download_chapters` 表（页级），高频刷新走普通字段不整树重渲；Logger TAG=`Download`
- **后台长时任务**：入队 `backgroundTaskManager.startBackgroundTask` + 常驻通知（`KEEP_BACKGROUND_RUNNING` 已声明），队列空闲时 `stopBackgroundTask`
- **落盘管线（存重组后图片）**：`JmApi.getChapter` 取 URL 列表 → `writePagesFile` 持久化页列表（离线兜底）→ 逐图 `Network.getBytes`（http 栈 → 下载栈双栈 + 魔数校验）→ `savePage` = `JmImage.decode` + `recombine`（反打乱）+ `imagePacker.packToData` JPEG（GIF 原样），tmp → rename 原子写入 `filesDir/download/{photoId}/`；读取时本地字节**只解码不重组**（ReaderImage 本地分支跳过 recombine）
- **详情缓存（DetailCache）**：下载入队时抓详情字段/章节列表/首页评论/封面双栈落盘（受「下载时保存详情数据」开关），`loadComic/localCoverPath/loadComments` 供详情页与下载页本地秒开；封面缺失 `ensureCover` 自愈；删除记录连带清理
- **离线阅读链路**：ReaderPage `loadChapter` 在线取章失败 → `DownloadManager.readChapterPages`（pages.json）兜底，无本地数据才报错；在线取章成功 → `cacheChapterPages` 回填（旧下载在线打开一次自动补全）；ReaderImage 本地优先（`localPathFor` → `readLocal` → decode），失败回退网络；GIF 喂 `Image()` 走 `fileUri.getUriFromPath` 转 `file://` URI（裸沙箱路径不渲染，封面同理）
- **入口与列表**：详情页「下载」→ 选章弹窗（全选/单章、已下载打勾）→「开始下载」（EMPHASIZED 按钮）入队，有 DONE 章节回显「已下载」；DownloadPage 聚合进度（页数/百分比）+ 暂停/继续/重试 + 删除清理（`removeComic` → 章节目录 + 详情缓存 + DB 记录）

### 实现约束（沿用）
- 任务对象用 class（`ChapterTask`），禁 any/globalThis；DB 一律 `CREATE TABLE IF NOT EXISTS` + ALTER 兼容旧库
- 进度更新勿整树重渲：进度放普通字段/item 级 `@Prop`，`ArrayDataSource.replaceAll` 局部刷新
- 文案进 `Translations.ets` 四处同步；颜色一律 `$r` 令牌；沙箱 `filesDir` 免权限
- 本地图片喂 `Image()` 必须 `fileUri.getUriFromPath(path)` 转 `file://` URI（ArkUI 官方要求）

### 参考实现（只读）
- `D:\desktop\JMComic-Crawler-Python-master\src\jmcomic\jm_toolkit.py` — `JmImageTools.download_image` / `decode_and_save`（下载即反打乱落盘的标准流程）
- `jmcomic-downloader` `download_manager.rs::stitch_img`（下载侧重组）、PicaComic 下载管理交互（任务列表/进度/暂停）

## 常见问题

### Q: 如何添加/修改设置项？
1. `common/Constants.ets` 的 `SettingsKeys` 加键
2. `pages/settings/` 对应页面加 UI：设置行放进 `ListItemGroup`（`groupHeader` 分组标题），每项一个 `ListItem`（`bg_surface` + 组首/末项圆角 16），组内分隔线用 `ListItemGroup.divider`；多选项设置用 `SettingSelect`（下拉菜单），开关用 `SettingSwitch`
3. `data/preferences/Settings.ets` 读写

### Q: 如何修改主题颜色？
编辑 `common/ThemeManager.ets` 中的颜色定义。

### Q: 如何排查图片显示问题？
```powershell
devecocli log clear
# 复现问题后：
devecocli log --keyword JmImage --from 2m
devecocli log --keyword ReaderImage --from 2m
```
关注：`recombine ok/skip: num=...`（分段数）、`non-image bytes`（反爬页）、`load failed`（解码异常）。

### Q: 连续滚动模式滑动跳动/停住后位置漂移？
```powershell
devecocli log clear
# 复现问题后：
devecocli log --keyword ReaderPage --from 2m
```
关注：`strip first index`（页码上报是否正常）、`strip anchor idx=... delay=...`（切章/跳页双重校正是否执行）、`strip guard released`（护栏是否按时释放）。排查顺序：
1. **占位高度跳变**：图片进场时比例是否已缓存（`preloadAround` 双向 10 是否追上滑动速度）；首次进章未读页比例未知时占位按 `PLACEHOLDER_RATIO=0.7` 估算，解码完成后高度会微调
2. **避让缺口（顶/底部露背景带）**：按官方示例7 核对整链——ReaderImage（根+分支）→ 占位 Column → ListItem → 内层 List 必须全部 expandSafeArea，且内层 List / 外层 Scroll 必须 `.clip(false)`；缺任一层或漏 clip 都会滚动后失效/被裁剪出缺口。整链齐全仍有缺口，再查渲染顺序（状态栏/浮层切换是否触发了依赖 topAvoid 的容器重排）
3. **@State 重渲**：`onDidZoom` 必须写普通字段 `stripZoom`；`stripActiveIdxs` 一类随滚动高频变更的 @State 不要恢复

### Q: API 请求全部失败怎么办？
检查域名切换（JM 设置页换线路）、查看 `devecocli log --keyword JmApi`，确认 token/时间戳生成与 AES 解密是否正常。

### Q: `systemMaterial` 沉浸光感不生效 / 日志报 "Material inactive: out of scope"？
1. **组件作用域限制（真机 hilog 实锤，最隐蔽的根因）**：`systemMaterial` 挂在**普通内容区组件**（自定义浮层、NavDestination 根、页面正文）上会被框架直接禁用并刷 `Material inactive: out of scope. Use component in navigation title bar or Tabbar.`（每处一条）。组件必须位于 **navigation title bar / TabBar 内**，或经组件 options 设置（`.title('', { systemMaterial })`、`bindSheet` 的 `systemMaterial` 等系统弹层）。修法：把浮层按钮移进 `NavDestination .title()` 自定义标题栏，并配 `barStyle: BarStyle.STACK`（标题栏悬浮在内容上层，保持 hero 沉浸延伸布局）。内容区其它按钮（详情页 hero 四按钮）结构上无法入 scope，**勿设材质**，保持裸图标或用半透明底模拟
2. `AppScope/app.json5` 缺 `"targetAPIVersion": 26`（app 级 enable metadata 生效要求 targetAPIVersion ≥ 26）
3. `module.json5` 缺 metadata `ohos.arkui.UIMaterial.state = "enable"`（须配在 entry 类型 module）
4. 材质层级在不透明背景**之下**（官方 FAQ）：组件须 `.backgroundColor(Color.Transparent)`，`systemMaterial` 放样式属性之后；**勿与 `backgroundBlurStyle` 同设**（模糊层覆盖材质层，且材质自带 materialFilter 已含模糊）；勿整页 + 子组件嵌套材质
5. 用 `uiMaterial.getMaterialInfo()` 确认 `state === 1`（ENABLE）；`type === 2` 为沉浸光感类型
6. 遗留债务：全项目 14 个页面（HistoryPage/SettingsPage/CommentsPage 等）仍在 NavDestination **根**挂 `.systemMaterial(...)` + `hideTitleBar(true)`——同样 out of scope 无效，各刷一条警告，后续应清理或迁入 `.title()`。`feature/compat-sdk20` 分支已把这些链式调用替换为带版本守卫的 `.attributeModifier(immersiveNavModifier)`（`common/Compat.ets`，解决的是 SDK20 API 起始版本问题；**作用域是否仍告警，合并后真机复核**）
