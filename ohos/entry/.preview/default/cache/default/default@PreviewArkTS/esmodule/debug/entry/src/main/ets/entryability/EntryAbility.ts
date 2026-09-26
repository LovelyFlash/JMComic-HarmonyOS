import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import UIAbility from "@ohos:app.ability.UIAbility";
import type Want from "@ohos:app.ability.Want";
import hilog from "@ohos:hilog";
import type window from "@ohos:window";
const DOMAIN = 0x0000;
const TAG = 'PicaComic';
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(DOMAIN, TAG, 'Ability onCreate');
    }
    onDestroy(): void {
        hilog.info(DOMAIN, TAG, 'Ability onDestroy');
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
        windowStage.loadContent('pages/MainPage', (err: Error): void => {
            if (err) {
                hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, TAG, 'Content loaded successfully');
        });
    }
    onWindowStageDestroy(): void {
        hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
    }
    onForeground(): void {
        hilog.info(DOMAIN, TAG, 'Ability onForeground');
    }
    onBackground(): void {
        hilog.info(DOMAIN, TAG, 'Ability onBackground');
    }
}
