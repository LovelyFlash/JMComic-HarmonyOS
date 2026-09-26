if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SearchBar_Params {
    placeholder?: string;
    keyword?: string;
    onSearch?: (keyword: string) => void;
    onTextChanged?: (text: string) => void;
    inputController?: TextInputController;
}
export class SearchBar extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__placeholder = new SynchedPropertySimpleOneWayPU(params.placeholder, this, "placeholder");
        this.__keyword = new SynchedPropertySimpleOneWayPU(params.keyword, this, "keyword");
        this.onSearch = () => { };
        this.onTextChanged = () => { };
        this.inputController = new TextInputController();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SearchBar_Params) {
        if (params.placeholder === undefined) {
            this.__placeholder.set('搜索漫画...');
        }
        if (params.keyword === undefined) {
            this.__keyword.set('');
        }
        if (params.onSearch !== undefined) {
            this.onSearch = params.onSearch;
        }
        if (params.onTextChanged !== undefined) {
            this.onTextChanged = params.onTextChanged;
        }
        if (params.inputController !== undefined) {
            this.inputController = params.inputController;
        }
    }
    updateStateVars(params: SearchBar_Params) {
        this.__placeholder.reset(params.placeholder);
        this.__keyword.reset(params.keyword);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__placeholder.purgeDependencyOnElmtId(rmElmtId);
        this.__keyword.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__placeholder.aboutToBeDeleted();
        this.__keyword.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __placeholder: SynchedPropertySimpleOneWayPU<string>;
    get placeholder() {
        return this.__placeholder.get();
    }
    set placeholder(newValue: string) {
        this.__placeholder.set(newValue);
    }
    private __keyword: SynchedPropertySimpleOneWayPU<string>;
    get keyword() {
        return this.__keyword.get();
    }
    set keyword(newValue: string) {
        this.__keyword.set(newValue);
    }
    private onSearch: (keyword: string) => void;
    private onTextChanged: (text: string) => void;
    private inputController: TextInputController;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/components/SearchBar.ets(11:5)", "entry");
            Row.width('100%');
            Row.height(44);
            Row.padding({ left: 12, right: 12 });
            Row.backgroundColor('#F5F5F5');
            Row.borderRadius(22);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('🔍');
            Text.debugLine("entry/src/main/ets/components/SearchBar.ets(12:7)", "entry");
            Text.fontSize(16);
            Text.margin({ right: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: this.placeholder, controller: this.inputController });
            TextInput.debugLine("entry/src/main/ets/components/SearchBar.ets(15:7)", "entry");
            TextInput.layoutWeight(1);
            TextInput.height(36);
            TextInput.fontSize(14);
            TextInput.backgroundColor('transparent');
            TextInput.onChange((value: string) => {
                this.onTextChanged(value);
            });
            TextInput.onSubmit(() => {
                this.onSearch(this.keyword);
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.keyword.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('×');
                        Text.debugLine("entry/src/main/ets/components/SearchBar.ets(27:9)", "entry");
                        Text.fontSize(18);
                        Text.fontColor('#999999');
                        Text.margin({ left: 8 });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
