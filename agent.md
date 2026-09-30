# JMComic HarmonyOS - Agent 开发指南

## 项目概述

禁漫天堂（JMComic）鸿蒙原生漫画阅读器，基于 ArkTS/ArkUI，HarmonyOS NEXT (API 26+)。
单漫画源（JM），包名 `com.jmcomic.harmony`，无第三方依赖。

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
│   ├── Logger.ets         -- hilog 封装（TAG 过滤：JmApi/JmImage/ReaderImage/Network）
│   ├── ThemeManager.ets   -- 深色策略 + 主题色（UI 颜色一律走 $r 资源令牌）
│   ├── Translations.ets   -- 中英文案
│   ├── ReadingConfig.ets  -- 阅读配置
│   ├── NavUtil.ets        -- 导航工具
│   └── ArrayDataSource.ets-- LazyForEach 数据源
├── data/
│   ├── api/JmApi.ets      -- 禁漫 API 客户端（token/data 加解密对照 jm_toolkit.py）
│   ├── database/Database.ets   -- SQLite（pica_comic.db: history/favorites/downloads）
│   ├── model/             -- Comic, Chapter, Comment, ComicPageData, ReaderParam
│   └── preferences/Settings.ets -- 键值存储
├── viewmodel/AppData.ets  -- 全局状态
├── components/
│   ├── ReaderImage.ets    -- 阅读器图片（下载→解码→反打乱→LRU 缓存，失败可重试）
│   ├── NetworkImage.ets   -- 普通网络图片（封面等，无需反打乱）
│   ├── ComicTile/ComicGrid/LoadingView/NavTitleBar/AppTopBar/AppIcon
│   └── SettingItem/SettingSection/SettingSwitch/SettingSelect
├── pages/
│   ├── MainPage.ets       -- 底部 Tab 主页
│   ├── DiscoverPage / SearchPage / PreSearchPage / CategoryPage / JmCategoryPage
│   ├── JmWeekPage / JmPromotePage / ComicDetailPage / CommentsPage
│   ├── HistoryPage / FollowPage / FavoritesContent / DownloadPage
│   ├── MePage / AccountsPage
│   ├── reader/ReaderPage.ets  -- 阅读器（单页 Swiper / 条漫 List 双模式）
│   └── settings/          -- SettingsPage(List+Select), ReadingSettings, JmSettings, AboutPage（均为内置标题栏 .title().hideTitleBar(false)）
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

### 调试工具

```powershell
devecocli log --keyword JmImage --from 5m       # 图片管线日志（recombine ok/skip、non-image bytes）
devecocli log --keyword ReaderImage --from 5m   # 阅读器图片加载日志（load failed 等）
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

### Q: API 请求全部失败怎么办？
检查域名切换（JM 设置页换线路）、查看 `devecocli log --keyword JmApi`，确认 token/时间戳生成与 AES 解密是否正常。
