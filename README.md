# JMComic HarmonyOS

禁漫天堂（JMComic / 18comic）的鸿蒙原生漫画阅读器，基于 ArkTS/ArkUI 开发，支持 HarmonyOS NEXT (API 26+)。

> 项目对照 [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python)（jm_toolkit.py / jm_config.py）与 [PicaComic](https://github.com/wgh136/PicaComic) 实现，API 加解密、图片反打乱算法均与参考实现逐行对齐。

## 功能特性

- **漫画浏览**: 最新、分类、每周必看、推荐、热搜词搜索
- **账号系统**: JM 账号登录、自动签到、收藏夹（多文件夹）、关注
- **在线阅读**: 六种阅读模式（从左至右/从右至左/从上至下/连续滚动/双页/双页反向）、多种翻页方式（点按/音量键/侧边）、自动翻页、双击/长按缩放、书签页码信息
- **沉浸阅读**: 进入阅读约 2.5 秒自动隐藏状态栏，打开工具栏/设置面板临时恢复，退出阅读自动还原
- **启动体验**: 独立启动页（首帧显示 + 历史数据预热 + 600ms 最短展示），窗口配置幂等初始化
- **连续滚动稳定**: 手势护栏 + 漂移欠账补偿 + 前瞻预热，消除图片加载引起的滑动跳动
- **图片反打乱**: 内置 JM 分段打乱逆向重组（scramble 解码），按 jm_toolkit.py `get_num` 计算分段数、`decode_and_save` 整段逆序重组像素（底段含余数行置顶，段内不旋转）
- **下载收藏**: 批量下载和历史记录（SQLite 持久化）
- **评论互动**: 漫画评论与回复查看
- **深色模式**: 跟随系统 / 禁用 / 启用
- **主题颜色**: 多种预设颜色
- **国际化**: 中文/英文
- **动态域名**: API 域名自动获取 + 多级回退（内置列表 → 远端配置 → 备用列表），图床分流可切换
- **双网络栈图片下载**: http 栈失败或返回反爬页时自动切换系统下载服务重试

## 下载

前往 [Releases](../../releases) 下载 HAP：

- `entry-default-signed.hap` — 已签名（Debug 证书），HarmonyOS NEXT 设备开启开发者模式后可直接安装
- `entry-default-unsigned.hap` — 未签名，可用自己的证书重新签名后安装

## 快速开始

### 环境要求

- DevEco Code / devecocli 1.3.x
- HarmonyOS SDK (API 26+)
- HarmonyOS 真机或模拟器

### 构建与运行

```powershell
# 在 ohos/ 目录下
devecocli build          # 构建 HAP
devecocli run            # 构建 + 安装 + 启动（自动选择设备）
devecocli device list    # 查看已连接设备
```

### 调试

```powershell
devecocli log --keyword JmImage --from 5m   # 查看图片管线日志
devecocli log --keyword ReaderPage --from 5m   # 阅读器滚动/状态栏诊断日志
devecocli log --crash --bundle-name com.jmcomic.harmony  # 崩溃日志
devecocli ui screenshot --path ./shot.png   # 截图
```

## 项目结构

```
ohos/
└── entry/src/main/ets/
    ├── common/          -- 通用工具 (Constants, Logger, Network, ThemeManager,
    │                       Translations, ReadingConfig, NavUtil, JmImage, ArrayDataSource)
    ├── data/
    │   ├── api/         -- JmApi（禁漫 API 客户端，加解密对照 jm_toolkit.py / jm_config.py）
    │   ├── database/    -- SQLite (pica_comic.db)
    │   ├── model/       -- Comic, Chapter, Comment, ComicPageData, ReaderParam
    │   └── preferences/ -- Settings 键值存储
    ├── viewmodel/       -- AppData 全局状态
    ├── components/      -- UI 组件 (ComicTile, ComicGrid, ReaderImage, NetworkImage,
    │                       LoadingView, NavTitleBar, AppTopBar, Setting* 系列)
    ├── pages/           -- 页面 (MainPage, LaunchPage, DiscoverPage, SearchPage, CategoryPage,
    │                       JmWeekPage, JmPromotePage, ComicDetailPage, CommentsPage,
    │                       HistoryPage, FollowPage, DownloadPage, MePage, AccountsPage,
    │                       reader/ReaderPage, settings/*)
    └── entryability/    -- EntryAbility 入口
```

## 技术要点

| 主题 | 说明 |
|------|------|
| 应用包名 | `com.jmcomic.harmony` |
| API 数据解密 | AES256-ECB，key = md5(time + APP_DATA_SECRET)，按 Python `data[:-data[-1]]` 去尾部 padding 后 UTF-8 解码 |
| 请求 token | 普通接口 md5(time + APP_TOKEN_SECRET)；`/chapter_view_template` 专用 md5(time + APP_TOKEN_SECRET_2) |
| 图片反打乱 | `get_num`（md5 末字符取 ord）算分段数 → 段序反转、底段含余数行置顶、段内不旋转（`JmImage.recombine`） |
| scramble_id | 从 chapter_view_template 页面抓取 `var scramble_id = (\d+);`，失败回退 220980 |
| APP 版本 | 默认 2.1.7（jm_config.py），运行时可被 version.json 动态覆盖 |
| 深色模式 | base/dark 语义颜色令牌（`$r('app.color.*')` 自动切换）+ `setColorMode` 策略（跟随系统/强制深浅），Surface 分层设计 |
| 启动流程 | LaunchPage 首帧 + `Database.queryHistory()` 预热 + 600ms 最短展示 → MainPage；`setupWindow` 幂等，启动页/主页共用 |
| 阅读状态栏 | 进入阅读 2.5s 后 `setSpecificSystemBarEnabled('status')` 隐藏；`@Watch` 联动工具栏/设置面板临时恢复；应用启动时兜底恢复 |
| 连续滚动稳定 | `onAreaChange` 锚点补偿（仅视口上方）+ 手势护栏（scroll/touch 期间记欠账、停稳补齐）+ strip 前10后3 预热；诊断日志 TAG=ReaderPage |
| 图片缓存 | 阅读器 PixelMap LRU 缓存（12 张） |
| 第三方依赖 | 无（oh-package.json5 dependencies 为空） |

## 许可证

MIT License

## 致谢

- [JMComic-Crawler-Python](https://github.com/hect0x7/JMComic-Crawler-Python) - API 加解密与图片解码参考实现
- [PicaComic](https://github.com/wgh136/PicaComic) - 图片反打乱与客户端交互参考实现
- [HarmonyOS SDK](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5) - 鸿蒙开发文档
