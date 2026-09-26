if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface NetworkImage_Params {
    url?: string;
    imgWidth?: number;
    imgHeight?: number;
    imgBorderRadius?: number;
    fit?: ImageFit;
    isDarkMode?: boolean;
}
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
const TAG = 'NetworkImage';
export class NetworkImage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__url = new SynchedPropertySimpleOneWayPU(params.url, this, "url");
        this.__imgWidth = new SynchedPropertySimpleOneWayPU(params.imgWidth, this, "imgWidth");
        this.__imgHeight = new SynchedPropertySimpleOneWayPU(params.imgHeight, this, "imgHeight");
        this.__imgBorderRadius = new SynchedPropertySimpleOneWayPU(params.imgBorderRadius, this, "imgBorderRadius");
        this.__fit = new SynchedPropertySimpleOneWayPU(params.fit, this, "fit");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: NetworkImage_Params) {
        if (params.url === undefined) {
            this.__url.set('');
        }
        if (params.imgWidth === undefined) {
            this.__imgWidth.set(120);
        }
        if (params.imgHeight === undefined) {
            this.__imgHeight.set(160);
        }
        if (params.imgBorderRadius === undefined) {
            this.__imgBorderRadius.set(8);
        }
        if (params.fit === undefined) {
            this.__fit.set(ImageFit.Cover);
        }
    }
    updateStateVars(params: NetworkImage_Params) {
        this.__url.reset(params.url);
        this.__imgWidth.reset(params.imgWidth);
        this.__imgHeight.reset(params.imgHeight);
        this.__imgBorderRadius.reset(params.imgBorderRadius);
        this.__fit.reset(params.fit);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__url.purgeDependencyOnElmtId(rmElmtId);
        this.__imgWidth.purgeDependencyOnElmtId(rmElmtId);
        this.__imgHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__imgBorderRadius.purgeDependencyOnElmtId(rmElmtId);
        this.__fit.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__url.aboutToBeDeleted();
        this.__imgWidth.aboutToBeDeleted();
        this.__imgHeight.aboutToBeDeleted();
        this.__imgBorderRadius.aboutToBeDeleted();
        this.__fit.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __url: SynchedPropertySimpleOneWayPU<string>;
    get url() {
        return this.__url.get();
    }
    set url(newValue: string) {
        this.__url.set(newValue);
    }
    private __imgWidth: SynchedPropertySimpleOneWayPU<number>;
    get imgWidth() {
        return this.__imgWidth.get();
    }
    set imgWidth(newValue: number) {
        this.__imgWidth.set(newValue);
    }
    private __imgHeight: SynchedPropertySimpleOneWayPU<number>;
    get imgHeight() {
        return this.__imgHeight.get();
    }
    set imgHeight(newValue: number) {
        this.__imgHeight.set(newValue);
    }
    private __imgBorderRadius: SynchedPropertySimpleOneWayPU<number>;
    get imgBorderRadius() {
        return this.__imgBorderRadius.get();
    }
    set imgBorderRadius(newValue: number) {
        this.__imgBorderRadius.set(newValue);
    }
    private __fit: SynchedPropertySimpleOneWayPU<ImageFit>;
    get fit() {
        return this.__fit.get();
    }
    set fit(newValue: ImageFit) {
        this.__fit.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.url.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create(this.url);
                        Image.debugLine("entry/src/main/ets/components/NetworkImage.ets(17:7)", "entry");
                        Image.width(this.imgWidth);
                        Image.height(this.imgHeight);
                        Image.borderRadius(this.imgBorderRadius);
                        Image.objectFit(this.fit);
                        Image.backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0');
                        Image.onError(() => {
                            Logger.debug(TAG, `Image load failed: ${this.url}`);
                        });
                    }, Image);
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("entry/src/main/ets/components/NetworkImage.ets(27:7)", "entry");
                        Column.width(this.imgWidth);
                        Column.height(this.imgHeight);
                        Column.borderRadius(this.imgBorderRadius);
                        Column.backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0');
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('No Image');
                        Text.debugLine("entry/src/main/ets/components/NetworkImage.ets(28:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(this.isDarkMode ? '#666666' : '#CCCCCC');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
        }, If);
        If.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
