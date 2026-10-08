# JMComic HarmonyOS

禁漫天堂（JMComic / 18comic）的鸿蒙原生漫画阅读器，基于 ArkTS / ArkUI 开发，支持 HarmonyOS NEXT（API 26+）。

> 本项目对照 [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python)（`jm_toolkit.py` / `jm_config.py`）与 [PicaComic](https://github.com/wgh136/PicaComic) 实现，API 加解密、图片反打乱算法均与参考实现逐行对齐。

## 目录

- [声明](#声明)
- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [项目架构总览](#项目架构总览)
- [技术栈](#技术栈)
- [模块目录说明](#模块目录说明)
- [核心模块深度解析](#核心模块深度解析)
- [数据流](#数据流)
- [权限说明](#权限说明)
- [构建配置](#构建配置)
- [安装调试](#安装调试)
- [开发指引](#开发指引)
- [反馈](#反馈)
- [致谢](#致谢)
- [许可证](#许可证)

## 声明

- 本项目是**开源学习与技术研究**项目，与禁漫天堂（JMComic / 18comic）官方无任何关联，未获其授权。
- 漫画内容的版权归版权方 / 原作者所有，本项目不存储、不分发任何漫画内容；请勿将本项目用于传播、盈利等商业用途。
- API 对接与算法实现对照以下开源参考项目完成，若有侵权请提 Issue 或联系仓库维护者，将第一时间处理：
  - [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python)
  - [PicaComic](https://github.com/wgh136/PicaComic)
- 本项目按 "AS IS" 提供，不作任何明示或暗示的担保；因使用本项目产生的任何风险与责任，由使用者自行承担。
- 请遵守所在地区的法律法规，未满 18 周岁者禁止使用。

## 项目简介

JMComic HarmonyOS 是一款运行在 HarmonyOS NEXT 上的单漫画源（JM）漫画客户端，覆盖「浏览 → 搜索 → 详情 → 阅读 → 收藏/追更」完整链路，重点投入阅读器的沉浸体验与渲染性能。

| 项目 | 说明 |
|------|------|
| 包名 | `com.jmcomic.harmony` |
| 当前版本 | 1.0.8（versionCode 9） |
| 目标 API | 26（HarmonyOS NEXT） |
| 开发语言 / UI 框架 | ArkTS / ArkUI 声明式（Stage 模型，单 `entry` HAP 模块） |
| 设备类型 | phone / tablet / 2in1 |
| 第三方运行时依赖 | 无（`oh-package.json5` dependencies 为空） |
| 参考基准 | JMComic-Crawler-Python（加解密 / 反打乱）、PicaComic（客户端交互） |

## 功能特性

**浏览与发现**
- 最新漫画、分类浏览、每周必看、推荐专题、热搜词搜索、作品 ID 精确搜索与搜索历史
- 发现页分区横滑列表（连载更新 / 推荐本本 / 去码全彩化等），主页、最新双 Tab

**账号与收藏**
- JM 账号登录、自动签到、多文件夹收藏夹（含收藏夹选择面板）、关注 / 追更
- 历史记录、下载记录、追更列表、账号管理，均由 SQLite 持久化

**在线阅读**
- 六种阅读模式：从左至右 / 从右至左 / 从上至下 / 连续滚动 / 双页 / 双页反向
- 多种翻页方式（点按 / 音量键 / 侧边）、自动翻页、双击与长按缩放、书签页码信息
- 单页 / 双页 / 连续三模式 `LazyForEach` 惰性构建，切章不再整章节点重建
- 连续滚动稳定：手势护栏 + 漂移欠账补偿 + 前瞻预热，消除图片加载引起的滑动跳动

**沉浸体验**
- 沉浸式详情页：封面模糊大图 + 深浅自适应渐变遮罩全屏延伸，悬浮光感材质标题栏
- 详情页信息栏：名称栏完整展示 ID / 作者 / 更新日期，标签按钮化、点击直达搜索
- 阅读器内状态栏全程隐藏（打开菜单 / 半模态不恢复，退出自动还原）
- 详情页点击即转场（章节图片由阅读器异步自取、loading 反馈、失败可重试）

**图片与网络**
- 图片反打乱：内置 JM 分段打乱逆向重组（scramble 解码），按 `jm_toolkit.py` 的 `get_num` 计算分段数、`decode_and_save` 整段逆序重组像素
- 双网络栈图片下载：http 栈失败或返回反爬页时自动切换系统下载服务栈重试
- 动态域名：内置列表 → 远端配置（密文下发，24h 更新）→ 备用列表多级回退，图床分流可切换

**个性化与其它**
- 深色模式：跟随系统 / 禁用 / 启用；多套预设主题色
- 中文 / 英文国际化
- 独立启动页（首帧显示 + 历史数据预热 + 600ms 最短展示）
- 应用内更新日志（关于页，按版本倒序展示历史更新内容）
- 漫画评论与回复查看、点赞 / 分享 / 下载入口

## 项目架构总览

单模块（`entry`）Stage 模型应用，UI 页全部挂在 `Navigation` + `NavDestination` 体系内，自下而上分为四层：

```
┌──────────────────────────────────────────────────────────────┐
│ UI 层  pages/ + components/                                  │
│   LaunchPage → MainPage(底部 4 Tab: 主页/收藏/发现/分类)     │
│   DiscoverPage · SearchPage · CategoryPage · ComicDetailPage │
│   reader/ReaderPage · history/follow/download/account…       │
│   settings/* · ComicTile/ComicGrid/ReaderImage/Setting*      │
├──────────────────────────────────────────────────────────────┤
│ 状态层  viewmodel/ + AppStorage                              │
│   AppData（全局状态）· @StorageProp(themeColor/darkMode…)    │
│   ArrayDataSource（LazyForEach 数据源，replaceAll / addAll）  │
├──────────────────────────────────────────────────────────────┤
│ 数据层  data/                                                 │
│   api/JmApi（加解密客户端）· database/Database（SQLite）      │
│   preferences/Settings（键值）· model/（Comic、Chapter…）      │
├──────────────────────────────────────────────────────────────┤
│ 基础层  common/                                               │
│   Network（双栈 HTTP）· JmImage（反打乱管线）· Constants      │
│   Logger · ThemeManager · Translations · ReadingConfig        │
│   NavUtil · ArrayDataSource                                   │
└──────────────────────────────────────────────────────────────┘
```

- **路由**：`main_pages.json` 仅含 `LaunchPage`（首帧）与 `MainPage`；其余 16 个页面通过 `router_map.json`（`buildFunction` 声明式路由）注册，由 `NavUtil.push(name, params)` 跳转。
- **启动流**：`LaunchPage` 首帧 → `Database.queryHistory()` 预热 → 600ms 最短展示 → `MainPage`；`setupWindow` 幂等，启动页与主页共用。
- **全局状态**：`AppData` 持有漫画源等全局信息；主题色 / 深色策略走 `AppStorage`，组件用 `@StorageProp` 响应。

## 技术栈

| 类别 | 选型 | 说明 |
|------|------|------|
| 语言 | ArkTS | TypeScript 方向的鸿蒙语言，全程严格类型（禁 `any` / `unknown`） |
| UI 框架 | ArkUI 声明式 | Stage 模型 `UIAbility`，`Navigation` + `NavDestination` 页面体系 |
| 状态管理 | V1（`@State` / `@Prop` / `@StorageLink` / `@StorageProp`） | 不与 V2 混用 |
| 网络 | `@ohos.net.http` | 统一收敛在 `common/Network.ets`（get / getWithStatus / getBytes / getBytesViaDownload / post） |
| 关系型数据库 | `@ohos.data.relationalStore` | SQLite `pica_comic.db`，安全级别 S1 |
| 键值存储 | `@ohos.data.preferences` | `data/preferences/Settings.ets` 封装的设置项 |
| 图片 | Image Kit（`@kit.ImageKit`） | 解码显式 `desiredPixelFormat: RGBA_8888`，PixelMap LRU 缓存（12 张） |
| 加密 | `@ohos.security.cryptoFramework` + 纯 ArkTS md5 | AES256-ECB 数据解密；md5Hex 已与 Python/Node hashlib 逐位对拍 |
| 日志 | `@ohos.hilog` | `Logger.ets` 按 TAG 过滤（JmApi / JmImage / ReaderImage / ReaderPage / Network…） |
| 材质 | `systemMaterial` 沉浸光感 | API 26 UIMaterial，见[核心模块深度解析](#核心模块深度解析) §5 |
| 构建 | hvigor（DevEco Studio / devecocli） | `modelVersion 5.0.0`，`assembleHap --mode module` |
| 单元测试 | `@ohos/hypium` 1.0.19 | devDependency，随 DevEco 模板生成 |
| 运行时第三方依赖 | **无** | 全部能力基于系统 Kit |

## 模块目录说明

```
JMComic-HarmonyOS/
├── README.md / LICENSE / agent.md     -- 项目文档（agent.md 为开发规范与工程要点）
├── scripts/
│   ├── build-verify.ps1               -- 构建验证：文件清单 → 编码 → ArkTS 合规 → 设计令牌 → hvigor 构建
│   └── code-audit.ps1                 -- 代码质量审计：ForEach/LazyForEach、硬编码色、any、emoji 图标等统计
├── convert_icons.* / create_icons.py  -- 图标（SVG → rawfile）转换辅助脚本
├── doc/                               -- 文档资料目录
└── ohos/                              -- DevEco 工程根（构建在此执行）
    ├── AppScope/
    │   ├── app.json5                  -- 应用级配置：包名、版本、targetAPIVersion
    │   └── resources/                 -- 应用级字符串（app_name、权限 reason 等）
    ├── build-profile.json5            -- 签名、SDK 版本、product（default）配置
    ├── oh-package.json5               -- 依赖声明（运行时为空，devDep hypium）
    ├── hvigorfile.ts / hvigor/        -- 构建脚本与缓存
    └── entry/                         -- 唯一 HAP 模块（entry 类型）
        └── src/main/
            ├── module.json5           -- 权限、ability、routerMap、UIMaterial metadata
            ├── resources/
            │   ├── base/element/      -- 浅色颜色令牌 color.json、字符串
            │   ├── dark/element/      -- 深色颜色令牌（同名自动切换）
            │   ├── rawfile/           -- SVG 图标、字体等原始资源
            │   └── profile/           -- main_pages.json、router_map.json
            └── ets/
                ├── entryability/      -- EntryAbility：窗口配置、状态栏、避让区广播
                ├── common/            -- 9 个基础模块（见下表）
                ├── data/
                │   ├── api/           -- JmApi.ets：禁漫 API 客户端
                │   ├── database/      -- Database.ets：SQLite 封装
                │   ├── preferences/   -- Settings.ets：键值存储封装
                │   └── model/         -- Chapter / Comic / ComicPageData / Comment / ReaderParam
                ├── viewmodel/         -- AppData.ets：全局状态
                ├── components/        -- 15 个复用组件
                ├── pages/             -- 17 个业务页面
                │   ├── reader/        -- ReaderPage.ets：阅读器
                │   └── settings/      -- SettingsPage / ReadingSettings / JmSettings / AboutPage
                └── plugin/            -- 预留插件目录
```

**`common/` 基础模块**

| 文件 | 职责 |
|------|------|
| `Constants.ets` | JM 密钥 / 域名 / UA（`ApiConstants`）、`SettingsKeys`、数据库常量、默认主题色 |
| `Network.ets` | HTTP 封装：文本 get/post、二进制 getBytes、下载栈 getBytesViaDownload、Cookie |
| `JmImage.ets` | 图片管线：请求头、魔数嗅探、分段数计算、decode、recombine（反打乱） |
| `Logger.ets` | hilog 封装与 TAG 过滤 |
| `ThemeManager.ets` | 深色策略（system / enabled / disabled）、主题色持久化、`windowBackground` 取值口 |
| `Translations.ets` | 中英文案（`Translations.t(key)`） |
| `ReadingConfig.ets` | 阅读配置（模式 / 翻页 / 缩放等） |
| `NavUtil.ets` | 路由跳转工具（push / pushSilent / back） |
| `ArrayDataSource.ets` | `IDataource` 实现：`replaceAll`（重建）/ `addAll`（追加）/ `clearData` |

**`components/` 复用组件**

- 内容类：`ComicTile`、`ComicGrid`、`LoadingView`、`AppIcon`、`AppTopBar`、`NavTitleBar`
- 图片类：`NetworkImage`（封面，无需反打乱）、`ReaderImage`（阅读器图片：下载 → 解码 → 反打乱 → LRU，失败可重试）
- 设置类：`SettingSection` / `SettingItem` / `SettingSwitch` / `SettingSelect` / `SettingCheckItem` / `SettingInfoItem` / `SettingCommon`

## 核心模块深度解析

### 1. JmApi —— API 客户端与加解密

对照 `jm_toolkit.py` 的 `JmCryptoTool` 与 `jm_config.py` 密钥参数实现：

- **请求 token**：普通接口 `md5Hex(time + APP_TOKEN_SECRET)`；`/chapter_view_template` 必须使用 `md5Hex(time + APP_TOKEN_SECRET_2)`，混用会 403。
- **响应解密**：响应 `data` 字段为 Base64 密文 → key = `md5Hex(time + APP_DATA_SECRET)`（time 与请求头一致）→ AES256-ECB 解密 → 按 Python 语义 `data[:-data[-1]]` 去尾部 padding → UTF-8 解码。
- **域名密文**：`ts` 传空串，key = `md5Hex(API_DOMAIN_SERVER_SECRET)`，解密前先去掉头部非 ASCII 字符。
- **scramble_id**：GET `/chapter_view_template?id={photoId}`，正则抓取 `var scramble_id = (\d+);`，失败回退 `220980`。
- **域名策略三级回退**：内置域名列表 → 远端域名列表（密文下发，24h 自动更新）→ 备用回退列表；图床分流（`JM_IMG_URLS` + 默认 host）可在 JM 设置页切换。
- **主要接口**：`/latest`、`/search`、`/album`（详情 + 章节）、`/chapter`（章节图片文件名）、`/hot_tags`、`/week` + `/week/filter`、`/categories`、`/login`、`/favorite`、`/check_in`、评论相关。
- APP 版本默认 `2.1.7`（`jm_config.py`），运行时可被远端 `version.json` 覆盖。

### 2. JmImage —— 图片反打乱管线

```
URL → Network.getBytes(http 栈) → 魔数嗅探(looksLikeImage)
   → 失败则 getBytesViaDownload(系统下载栈) → 再嗅探
   → Image Kit decode(RGBA_8888) → JmImage.recombine(反打乱) → PixelMap → Image
```

- **分段数 `getSegmentationNum`**：`aid < scrambleId → 0`；`< 268850 → 10`；否则 `md5(aid + 文件名去扩展名)` 的**末字符取 ASCII 码**，`< 421926 → ord % 10 * 2 + 2`，否则 `ord % 8 * 2 + 2`。
- **反打乱 `recombine`**：对齐 `decode_and_save` / `_segmentationPicture` / `stitch_img` —— 源图按 `floor(h / num)` 切段、末段附带 `h % num` 余数行；目标图从末段开始**整段逆序**贴合，**段内不旋转**；全量读像素后重建 PixelMap（显式 `srcPixelFormat: RGBA_8888`）。
- **坑位**：`createPixelMap()` 默认 `editable: false`，不能对解码产物原地 `writePixels`，必须重建。
- **缓存与 GIF**：`ReaderImage` 内置 LRU（12 张 PixelMap，按 URL）；GIF 跳过反打乱直接显示。

### 3. ReaderPage —— 阅读器

- **进入与切章（push-first）**：详情页 `startReading` 同步转场（`NavUtil.push` 传 `images=[]`），阅读器自取首章（`silent` 模式：不弹 toast、不落盘防覆盖进度），取图完成后再做续读检查；失败置 `chapterError` → 内容层「错误 + 重试」遮罩。
- **三模式 LazyForEach**：单页 / 双页 Swiper 与连续 List 的数据源 `singleSource` / `dualSource` / `stripSource` 均为 `ArrayDataSource.replaceAll`，切章 / 进入只创建 visible + cachedCount 节点（原 ForEach eager 构建一帧重建 50–120 个页面节点是掉帧主因）。
- **状态栏全程隐藏**：进入后 400ms（跨过 push 转场）隐藏、退出恢复，世代号 `statusBarGen` 防乱序；打开工具栏 / 半模态**不恢复**状态栏（恢复会回写 `topAvoidHeight` → `@StorageProp` 整树重渲染导致图片错位），工具栏 padding 直接联动 `topAvoidHeight`。
- **连续滚动稳定**：外层 `Scroll`（pinch 缩放 + 缩放态平移）+ 内层 `List`（`cachedCount` + 嵌套滚动 PARENT_FIRST）；`onDidZoom` 写普通字段避免逐帧重渲；锚点 `scrollToIndex` + 80/400ms 两次重校；护栏期间屏蔽页码上报；进度 500ms 防抖落盘、退出前强制 flush。
- **expandSafeArea 整链**：图片 → 占位 Column → ListItem → 内层 List 全链设置，且滚动容器必须 `clip(false)`，否则出现避让缺口。
- 阅读器 PixelMap LRU 缓存 12 张，诊断日志 TAG=`ReaderPage`（`fetchMs` / `totalMs` / `strip anchor`…）。

### 4. 列表渲染性能 —— LazyForEach 与 ArrayDataSource

- 长列表 / 网格一律 `LazyForEach` + `ArrayDataSource`（历史、下载、评论、每周榜单、收藏、发现、详情章节网格）：
  - **数据整体替换**（重新拉取）：`this.dataSource = new ArrayDataSource(data)` 重建实例；
  - **追加加载**：`dataSource.addAll(newItems)`（去重后追加）；
  - **就地刷新**（章节排序、展开全部）：`chapterSource.replaceAll(list)`。
- 空态判断用 `dataSource.totalCount() === 0`；列表尾部可挂静态 footer `ListItem`（模板参考 `JmPromotePage`）。
- `ForEach` / `LazyForEach` 必须提供**稳定 key**（如 `historyRow{id}`、章节 `id + order`）；`@Prop` / `@State` 属性级绑定在 LazyForEach 节点创建后仍生效，因此高亮 / 主题色可安全绑定。

### 5. 沉浸光感材质（systemMaterial）

生效四条件（缺一即被框架禁用并刷 `Material inactive: out of scope`）：

1. `AppScope/app.json5` `targetAPIVersion ≥ 26`；
2. `module.json5` metadata `ohos.arkui.UIMaterial.state = enable`；
3. **组件必须位于 navigation title bar / TabBar 内**（内容区组件一律 out of scope —— 详情页返回 / 收藏按钮经 `NavDestination .title()` + `barStyle: BarStyle.STACK` 悬浮标题栏实现）；
4. 材质层级在不透明背景之下：组件 `backgroundColor(Transparent)`、`systemMaterial` 放样式属性之后、勿与 `backgroundBlurStyle` 同设、勿整页 + 子组件嵌套材质。

### 6. Network —— 双网络栈与降级

- 文本统一 `get` / `post`，二进制 `getBytes`（ARRAY_BUFFER）；全局统一走 `Network` 封装，页面不得直接 `http.createHttp()`。
- 图片字节优先 http 栈，失败或嗅探到非图片字节（反爬页）自动切 `getBytesViaDownload`（系统下载服务栈）重试。
- Cookie 统一维护（登录态依赖），域内 `getCookie(host)`。

### 7. Database / Settings —— 持久化

- SQLite `pica_comic.db`（S1）5 张表：`history`（阅读进度）、`favorites`（收藏）、`downloads`（下载记录）、`follows`（追更）、`comments`（评论缓存），`Database.init` 后 `CREATE TABLE IF NOT EXISTS`。
- `Settings.ets` 封装 preferences：深色 / 主题色 / 语言 / 阅读相关 / JM 域名与账号等键值（`SettingsKeys` 统一定义）。

### 8. ThemeManager 与国际化

- 颜色一律 `$r('app.color.*')` 资源令牌，`base/element/color.json` 与 `dark/element/color.json` 同名定义，深浅切换由系统资源限定词目录自动完成，**组件内不做任何模式判断**。
- 深色策略 `setDarkModePolicy('system' | 'enabled' | 'disabled')` → `setColorMode(NOT_SET | DARK | LIGHT)`；品牌色 `setThemeColor` 持久化 + `AppStorage('themeColor')`。
- 状态栏图标色按有效深浅状态由 `EntryAbility.systemBarNotifier` 设置。
- `Translations.t(key)` 提供中英文案，语言设置可切换。

## 数据流

**① 网络请求流（API）**

```
页面(@State/ArrayDataSource)
  → JmApi.xxx()
      ├─ 组装 time + md5 token 请求头（区分 TOKEN / TOKEN_2）
      └─ 域名选择：内置 → 远端(密文, 24h 缓存) → 回退列表
  → Network.get/post（@ohos.net.http）
  → 响应 data(Base64) → AES256-ECB 解密 → 去尾部 padding → JSON.parse
  → Model（Comic/Chapter/Comment/ComicPageData…）
  → 回写 @State 或 new ArrayDataSource(data) / addAll
  → LazyForEach 局部刷新 → UI
```

**② 图片流（阅读器）**

```
ReaderImage(onAppear/预热窗口)
  → Network.getBytes(http 栈, 带 Referer/UA)
  → 魔数嗅探 → 非图片 → getBytesViaDownload(下载栈) 重试
  → JmImage.decode(RGBA_8888) → JmImage.recombine(分段逆序反打乱)
  → PixelMap LRU(12) 命中则直接复用
  → Image(PixelMap) 渲染（占位比例缓存，高度不跳变）
```

**③ 持久化流**

```
写：收藏 / 历史 / 追更 / 下载 / 评论操作 → Database(SQLite pica_comic.db)
    阅读进度 → strip 500ms 防抖 + 退出 flush → Database.insertHistory
    设置项 → Settings(preferences)
读：启动 LaunchPage → Database.queryHistory() 预热 → MainPage 各 Tab 按需查询
    阅读器进入 → getReadingProgress → 续读弹窗
```

**④ 导航流**

```
NavUtil.push('comicDetail', { comicId, title, source })
  → router_map.json 解析 → buildFunction 构建 NavDestination
  → 页面内再 push（reader / comments / settings / follows …）
  → back 栈逐层返回；底部 Tab 由 MainPage(Swiper + TabBar) 承载
```

## 权限说明

`ohos/entry/src/main/module.json5` 声明的权限及用途：

| 权限 | 类型 | 用途 |
|------|------|------|
| `ohos.permission.INTERNET` | normal | 访问 JM API 与图床，下载漫画图片 |
| `ohos.permission.GET_NETWORK_INFO` | normal | 读取网络连接状态，用于在线 / 离线提示与请求失败引导 |
| `ohos.permission.GET_WIFI_INFO` | normal | 读取 WLAN 状态，用于网络环境识别与图片线路选择参考 |
| `ohos.permission.READ_MEDIA` | user_grant（reason：用于保存和读取漫画图片到媒体库，`when: inuse`） | 将漫画图片保存 / 读取到系统媒体库（相册），授权时机为使用期间 |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | normal | 保证下载等任务在应用退到后台时可持续运行 |

> user_grant 权限会在运行时弹窗请求，拒绝后仅影响对应功能（媒体库读写），不影响在线浏览与阅读。

## 构建配置

**应用级（`ohos/AppScope/app.json5`）**

```json5
{
  bundleName: "com.jmcomic.harmony",
  versionCode: 9,
  versionName: "1.0.8",
  targetAPIVersion: 26
}
```

**工程级（`ohos/build-profile.json5`）**

- `products[0]`（`default`）：`compatibleSdkVersion: '26.0.0'`、`targetSdkVersion: '26.0.0'`、`runtimeOS: 'HarmonyOS'`、`strictMode.caseSensitiveCheck: true`
- `signingConfigs.default`：HarmonyOS 调试签名材料（自动创建的 debug 证书，路径位于 `~/.ohos/config/`），产物即为可安装的 `entry-default-signed.hap`
- `modules`：仅 `entry` 单模块

**模块级（`entry/src/main/module.json5`）**

- `mainElement: EntryAbility`，`deviceTypes: [phone, tablet, 2in1]`
- `pages: $profile:main_pages`（LaunchPage / MainPage）、`routerMap: $profile:router_map`（16 条声明式路由）
- metadata：`ohos.arkui.UIMaterial.state = enable`（沉浸光感总开关）

**依赖（`ohos/oh-package.json5`）**：`modelVersion 5.0.0`；运行时依赖为空，仅 devDependency `@ohos/hypium 1.0.19`。

**校验脚本（仓库根 `scripts/`）**

| 脚本 | 作用 |
|------|------|
| `build-verify.ps1` | 文件清单 → 编码损坏检查（U+FFFD）→ ArkTS 合规（any/unknown/V2+StorageLink）→ 设计令牌（禁止 `isDarkMode ? '#'` 硬编码）→ `hvigorw assembleHap` 构建，出现 `ArkTS:ERROR` 即失败 |
| `code-audit.ps1` | 统计 ForEach vs LazyForEach、硬编码色、嵌套三元、emoji 图标、SVG 引用、编码错误等质量指标 |

## 安装调试

**环境要求**

- DevEco Code / devecocli 1.3.x（或 DevEco Studio 自带 hvigor）
- HarmonyOS SDK（API 26+）
- HarmonyOS NEXT 真机或模拟器

**获取安装包**：前往 [Releases](https://github.com/LovelyFlash/JMComic-HarmonyOS/releases) 下载 HAP：

- `entry-default-signed.hap` —— 已签名（Debug 证书），设备开启开发者模式后可直接安装
- `entry-default-unsigned.hap` —— 未签名，可用自己的证书重新签名后安装

**构建与运行**（在 `ohos/` 目录下）：

```powershell
devecocli build            # 构建 HAP
devecocli run              # 构建 + 安装 + 启动（自动选择设备）
devecocli run --skip-build # 跳过构建，部署已有产物
devecocli run --uninstall  # 先卸载再装（解决签名不一致）
devecocli device list      # 查看已连接设备
devecocli build clean      # 清理构建产物
```

**仅编译验证**（不安装，查编译错误；在 `ohos/` 目录下）：

```powershell
$env:PATH = "D:\DevEco Studio\tools\node;" + $env:PATH
$env:DEVECO_SDK_HOME = "D:\DevEco Studio\sdk"
& "D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default --no-daemon
```

既有 deprecated / showToast / 2in1 警告可忽略，`ArkTS:ERROR` 为真实错误；增量编译约 15s。

**调试命令**：

```powershell
devecocli log --keyword JmImage --from 5m        # 图片管线日志（recombine ok/skip、non-image bytes）
devecocli log --keyword ReaderPage --from 5m     # 阅读器滚动诊断日志
devecocli log --keyword JmApi --from 5m          # API/token/解密日志
devecocli log --crash --bundle-name com.jmcomic.harmony  # 崩溃日志
devecocli log clear                              # 复现问题前清空 hilog
devecocli ui screenshot --path ./shot.png        # 截图
devecocli ui layout --format json                # UI 树检查
```

> 注意：真机锁屏时 `devecocli run` 启动会报 `10106102`，需先解锁屏幕。

## 开发指引

**1. 环境与本地校验**

```powershell
# 仓库根目录：一键校验（编码 / ArkTS / 设计令牌 / 构建）
powershell -File scripts\build-verify.ps1
# 代码质量统计
powershell -File scripts\code-audit.ps1
```

**2. ArkTS 编码规范**

1. 禁止 `globalThis`，使用模块级变量代替；
2. 禁止 `any` / `unknown`，必须显式声明类型；
3. 禁止对象字面量类型，使用 `class` 或 `interface`；
4. `import` 必须在文件顶部；
5. 类型断言用 `as` 而非 `!`；异步 `async/await + try-catch`，Promise 结果必须 await 后再取属性。

**3. 颜色与主题规范**

1. UI 颜色一律 `$r('app.color.*')` 资源令牌（base / dark 同名自动切换），禁止硬编码色值（阅读器固定色、图片遮罩等独立令牌除外）；
2. 新增颜色必须在 `base/element/color.json` 与 `dark/element/color.json` **同时**定义；
3. 品牌色用 `@StorageProp('themeColor')`，默认值取 `Constants.DEFAULT_THEME_COLOR`，禁止硬编码 `'#2563EB'`；
4. 不要为颜色变化挂状态（禁止 `@StorageProp('isDarkMode')` 触发重绘），资源切换无需逻辑；
5. 系统 API 需要具体色值时，唯一取值口是 `ThemeManager.windowBackground`。

**4. 组件与性能规范**

1. 使用 `@Component` + V1 状态管理，禁止与 V2 混用；
2. 图片必须指定占位 / 错误态；
3. `ForEach` / `LazyForEach` 必须提供稳定 key；
4. 长列表 / 网格一律 `LazyForEach` + `ArrayDataSource`（见[核心模块深度解析](#核心模块深度解析) §4）；
5. HTTP 一律走 `Network`，SQLite 走 `Database`，键值走 `Settings`，日志走 `Logger`。

**5. 新增页面**

1. 在 `resources/base/profile/router_map.json` 注册 `name` / `pageSourceFile` / `buildFunction`；
2. 页面组件内实现 `export function XxxPageBuilder()` 构建入口；
3. 用 `NavUtil.push('xxx', params)` 跳转（参数经 `pageParam` 接收）。

**6. 新增设置项**

1. `common/Constants.ets` 的 `SettingsKeys` 加键；
2. `pages/settings/` 对应页面加 UI：设置行放进 `ListItemGroup`（组标题 + 每项 `ListItem` + 圆角与 `divider`），多选用 `SettingSelect`、开关用 `SettingSwitch`；
3. `data/preferences/Settings.ets` 读写。

**7. 问题排查**

```powershell
devecocli log clear
# 复现问题后：
devecocli log --keyword JmImage --from 2m    # 图片不显示：recombine ok/skip、non-image bytes、load failed
devecocli log --keyword ReaderPage --from 2m # 滚动跳动：strip first index / anchor / guard released
devecocli log --keyword JmApi --from 2m      # 请求失败：token、时间戳、AES 解密
```

**8. 版本发布流程（维护者）**

1. 功能 / 修复以 `feat(x):`、`fix(x):`、`perf(x):` 单独提交，**与版本提交分离**；
2. 修改 `AppScope/app.json5`（`versionCode + 1`、`versionName`）并提交 `chore(release): vX.Y.Z`；
3. 运行 `scripts\build-verify.ps1` 产出签名 / 未签名 HAP；
4. `git fetch --tags` 后打轻量 tag 指向 chore 提交，推送分支 + tag；
5. `gh release create <tag> <signed.hap> <unsigned.hap> --title "JMComic HarmonyOS vX.Y.Z" --notes-file <UTF-8 说明>`。

## 反馈

- 提交 Issue：[github.com/LovelyFlash/JMComic-HarmonyOS/issues](https://github.com/LovelyFlash/JMComic-HarmonyOS/issues)
- 报告问题时请尽量附带：
  1. 设备型号与 HarmonyOS 版本（设置 → 关于本机）；
  2. 应用版本（设置 → 关于，versionCode）；
  3. 复现步骤与预期 / 实际表现；
  4. 相关日志：`devecocli log clear` 后复现，再执行 `devecocli log --keyword <TAG> --from 2m`（图片问题用 `JmImage` / `ReaderImage`，滚动问题用 `ReaderPage`，接口问题用 `JmApi`），或 `--crash --bundle-name com.jmcomic.harmony`。
- 功能建议与 PR 同样欢迎；涉及主题色 / 结构性改动请先开 Issue 讨论。

## 致谢

- [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python) —— API 加解密与图片解码参考实现
- [PicaComic](https://github.com/wgh136/PicaComic) —— 图片反打乱与客户端交互参考实现
- [HarmonyOS SDK](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5) —— 鸿蒙开发文档

## 许可证

本项目基于 **MIT License** 开源，详见 [LICENSE](LICENSE)。

```
MIT License
Copyright (c) 2026 LovelyFlash
```

在保留上述版权声明与许可声明的前提下，可自由地使用、复制、修改、合并、发布、分发、再许可及售卖本软件的副本。
