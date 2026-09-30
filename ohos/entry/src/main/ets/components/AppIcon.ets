// components/AppIcon.ets - 统一图标组件（SymbolGlyph）
@Component
export struct AppIcon {
  @Prop symbol: Resource = $r('sys.symbol.questionmark_circle')
  @Prop size: number = 24
  @Prop color: ResourceColor = $r('app.color.text_primary')

  build() {
    SymbolGlyph(this.symbol)
      .fontSize(this.size)
      .fontColor([this.color])
  }
}
