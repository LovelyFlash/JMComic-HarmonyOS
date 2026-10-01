// components/SettingCommon.ets - 设置项公共定义（分组内圆角位置 + 卡片圆角计算）
export enum SettingCorner {
  ALL = 0,
  FIRST,
  MIDDLE,
  LAST
}

/** 按组内位置返回卡片圆角（单项=四角 16，首项=上 16，中间=无圆角，末项=下 16） */
export function settingCornerRadius(corner: SettingCorner): BorderRadiuses {
  if (corner === SettingCorner.FIRST) {
    return { topLeft: 16, topRight: 16 };
  }
  if (corner === SettingCorner.MIDDLE) {
    return {};
  }
  if (corner === SettingCorner.LAST) {
    return { bottomLeft: 16, bottomRight: 16 };
  }
  return { topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 16 };
}
