// common/Compat.ets - SDK 6.0.0(20) 兼容层
// compatibleSdkVersion 降为 6.0.0(20) 后，新 API 必须按设备版本判断保护：
// deviceInfo.sdkApiVersion 即设备 OpenHarmony API Level（26.0.0(26)、6.1.0(23)、6.0.0(20)...），
// 在 if 判断中直接使用可同时消除编译期 COMPATIBILITY 告警。
import { deviceInfo } from '@kit.BasicServicesKit';
import { uiMaterial } from '@kit.ArkUI';

/**
 * NavDestination 沉浸光感材质修饰器。
 * systemMaterial 自 API 26.0.0 起可用，低版本设备降级为无系统材质
 * （各页 title/background 已有实色背景，视觉可接受）。
 */
export class ImmersiveNavModifier implements AttributeModifier<NavDestinationAttribute> {
  applyNormalAttribute(instance: NavDestinationAttribute): void {
    // 外层 sdkApiVersion：apiAvailable 自 26.0.0 起可用，低版本设备不可直接调用；
    // 内层 apiAvailable：官方推荐的 26.0.0 告警消除写法
    if (deviceInfo.sdkApiVersion >= 26) {
      if (deviceInfo.apiAvailable('26.0.0')) {
        instance.systemMaterial(new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.ULTRA_THIN
        }));
      }
    }
  }
}

export const immersiveNavModifier: ImmersiveNavModifier = new ImmersiveNavModifier();
