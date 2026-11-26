// components/SearchBar.ets - 统一搜索栏（按钮态/输入态 + 可选尾部控件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';

@Component
export struct SearchBar {
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR;
  /** 搜索栏文字；按钮态用作展示，输入态绑定 TextInput */
  @Prop text: string = '';
  @Prop placeholder: string = '';
  /** false=按钮态（首页入口），true=输入态（搜索页） */
  @Prop editable: boolean = true;
  @Prop showClear: boolean = false;
  @Prop itemId: string = 'searchBar';
  /** 搜索页排序下拉（可选，位于清空按钮左侧） */
  @Prop showSortSelect: boolean = false;
  @Prop sortOptions: SelectOption[] = [];
  @Prop sortIndex: number = 0;
  @Prop sortLabel: string = '';
  onTextChange: (value: string) => void = () => {};
  onSubmit: () => void = () => {};
  onClear: () => void = () => {};
  onTap: () => void = () => {};
  onSortSelect: (index: number) => void = () => {};

  @Builder
  contentRow() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
      if (this.editable) {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .onChange((value: string) => {
            this.onTextChange(value);
          })
          .onSubmit(() => {
            this.onSubmit();
          })
        if (this.showSortSelect) {
          Select(this.sortOptions)
            .selected(this.sortIndex)
            .value(this.sortLabel)
            .font({ size: 13 })
            .fontColor($r('app.color.text_secondary'))
            .selectedOptionFontColor(this.themeColor)
            .optionFontColor($r('app.color.text_primary'))
            .menuBackgroundColor($r('app.color.bg_elevated'))
            .menuAlign(MenuAlignType.END)
            .height(28)
            .constraintSize({ maxWidth: 104 })
            .onSelect((index: number) => {
              this.onSortSelect(index);
            })
        }
        if (this.showClear) {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontSize(18)
            .fontColor([$r('app.color.text_tertiary')])
            .onClick(() => {
              this.onClear();
            })
        }
      } else {
        Text(this.placeholder)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.Transparent)
    .borderRadius(22)
    .border({ width: 0.5, color: $r('app.color.divider') })
    .shadow({ radius: 8, color: '#1F000000', offsetX: 0, offsetY: 2 })
    .clip(true)
    .id(this.itemId)
  }

  build() {
    if (this.editable) {
      this.contentRow()
    } else {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        this.contentRow()
      }
      .width('100%')
      .height(44)
      .padding(0)
      .backgroundColor(Color.Transparent)
      .borderRadius(22)
      .clip(true)
      .onClick(() => {
        this.onTap();
      })
    }
  }
}
