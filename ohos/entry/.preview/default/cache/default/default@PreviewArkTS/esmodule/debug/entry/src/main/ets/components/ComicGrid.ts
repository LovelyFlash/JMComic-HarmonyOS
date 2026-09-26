if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ComicGrid_Params {
    comics?: Comic[];
    columns?: number;
    onTap?: (id: string, source: string) => void;
}
import type { Comic } from '../data/model/Comic';
import { NetworkImage } from "@bundle:com.picacomic.harmony/entry/ets/components/NetworkImage";
export class ComicGrid extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__comics = new SynchedPropertyObjectOneWayPU(params.comics, this, "comics");
        this.__columns = new SynchedPropertySimpleOneWayPU(params.columns, this, "columns");
        this.onTap = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ComicGrid_Params) {
        if (params.comics === undefined) {
            this.__comics.set([]);
        }
        if (params.columns === undefined) {
            this.__columns.set(3);
        }
        if (params.onTap !== undefined) {
            this.onTap = params.onTap;
        }
    }
    updateStateVars(params: ComicGrid_Params) {
        this.__comics.reset(params.comics);
        this.__columns.reset(params.columns);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__comics.purgeDependencyOnElmtId(rmElmtId);
        this.__columns.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__comics.aboutToBeDeleted();
        this.__columns.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __comics: SynchedPropertySimpleOneWayPU<Comic[]>;
    get comics() {
        return this.__comics.get();
    }
    set comics(newValue: Comic[]) {
        this.__comics.set(newValue);
    }
    private __columns: SynchedPropertySimpleOneWayPU<number>;
    get columns() {
        return this.__columns.get();
    }
    set columns(newValue: number) {
        this.__columns.set(newValue);
    }
    private onTap: (id: string, source: string) => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Grid.create();
            Grid.debugLine("entry/src/main/ets/components/ComicGrid.ets(12:5)", "entry");
            Grid.columnsTemplate(this.templateString());
            Grid.columnsGap(8);
            Grid.rowsGap(8);
            Grid.width('100%');
            Grid.padding(12);
        }, Grid);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const comic = _item;
                {
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        GridItem.create(() => { }, false);
                        GridItem.debugLine("entry/src/main/ets/components/ComicGrid.ets(14:9)", "entry");
                    };
                    const observedDeepRender = () => {
                        this.observeComponentCreation2(itemCreation2, GridItem);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/components/ComicGrid.ets(15:11)", "entry");
                            Column.width('100%');
                            Column.padding(6);
                            Column.onClick(() => {
                                this.onTap(comic.id, comic.source);
                            });
                        }, Column);
                        {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                if (isInitialRender) {
                                    let componentCall = new NetworkImage(this, { url: comic.coverUrl, imgWidth: 100, imgHeight: 140, imgBorderRadius: 6 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/components/ComicGrid.ets", line: 16, col: 13 });
                                    ViewPU.create(componentCall);
                                    let paramsLambda = () => {
                                        return {
                                            url: comic.coverUrl,
                                            imgWidth: 100,
                                            imgHeight: 140,
                                            imgBorderRadius: 6
                                        };
                                    };
                                    componentCall.paramsGenerator_ = paramsLambda;
                                }
                                else {
                                    this.updateStateVarsOfChildByElmtId(elmtId, {
                                        url: comic.coverUrl, imgWidth: 100, imgHeight: 140, imgBorderRadius: 6
                                    });
                                }
                            }, { name: "NetworkImage" });
                        }
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(comic.title);
                            Text.debugLine("entry/src/main/ets/components/ComicGrid.ets(17:13)", "entry");
                            Text.fontSize(12);
                            Text.maxLines(2);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                            Text.width('100%');
                            Text.margin({ top: 6 });
                        }, Text);
                        Text.pop();
                        Column.pop();
                        GridItem.pop();
                    };
                    observedDeepRender();
                }
            };
            this.forEachUpdateFunction(elmtId, this.comics, forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        Grid.pop();
    }
    private templateString(): string {
        let t = '';
        for (let i = 0; i < this.columns; i++) {
            t += '1fr';
            if (i < this.columns - 1) {
                t += ' ';
            }
        }
        return t;
    }
    rerender() {
        this.updateDirtyElements();
    }
}
