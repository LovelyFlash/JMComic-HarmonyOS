// common/Changelog.ets - 应用内更新日志数据（按版本倒序，最新在前）
export class ReleaseNote {
  version: string;
  date: string;
  items: string[];

  constructor(version: string, date: string, items: string[]) {
    this.version = version;
    this.date = date;
    this.items = items;
  }
}

export class Changelog {
  static readonly releases: ReleaseNote[] = [
    new ReleaseNote('1.0.8', '2026-10-08', [
      '更新项目文档：README 同步版本信息、功能特性与构建配置说明'
    ]),
    new ReleaseNote('1.0.7', '2026-10-07', [
      '搜索支持直接输入漫画 ID，可直接打开对应详情页',
      '详情页新增信息栏：名称、ID、作者与标签统一为按钮式样式，点击即可搜索',
      '标签放大统一字号与间距，新增「标签」标题，修复空白标签气泡',
      '名称过长时自动限制宽度并换行显示，不再超出屏幕',
      '完善日志系统：日志级别控制、全局崩溃与异常捕获、路由与网络日志',
      '兼容 HarmonyOS API 26'
    ]),
    new ReleaseNote('1.0.6', '2026-10-02', [
      '历史、下载、评论、每周榜单、收藏、发现页与详情页章节网格改用懒加载，长列表滚动更流畅',
      '详情页章节支持排序与显示全部即时刷新',
      '追更、账号页标题栏统一为系统标题栏格式'
    ]),
    new ReleaseNote('1.0.5', '2026-10-02', [
      '修复收藏夹弹窗对齐阅读器容器并固定底部输入栏'
    ]),
    new ReleaseNote('1.0.4', '2026-10-02', [
      '修复详情页沉浸光感材质按作用域移入悬浮标题栏'
    ]),
    new ReleaseNote('1.0.3', '2026-10-02', [
      '沉浸式详情页改版',
      '阅读器渲染性能优化'
    ]),
    new ReleaseNote('1.0.2', '2026-10-01', [
      '阅读器条漫重构、音量键/自动翻页、图片画质设置、侧边进度条',
      '启动页与阅读器状态栏自动隐藏',
      '设置页列表布局重构',
      '深色模式语义化颜色资源适配'
    ]),
    new ReleaseNote('1.0.1', '2026-09-30', [
      '修复登录状态在重启后丢失',
      '适配系统安全区'
    ]),
    new ReleaseNote('1.0.0', '2026-09-29', [
      '首个版本：JMComic 核心功能、加密与图像还原对齐原版',
      '阅读器、设置、历史/收藏/下载、发现与搜索完整功能',
      'HarmonyOS 设计语言适配与深色模式'
    ])
  ];
}
