// components/AppTopBar.ets - 统一顶栏（返回 + 标题 + 动作按钮）

@Component
export struct AppTopBar {
  @Prop title: string = ''
  @Prop showBack: boolean = true
  @Prop actionCount: number = 0
  
  
  onBack: () => void = () => {}
  onAction1: () => void = () => {}
  onAction2: () => void = () => {}
  onAction3: () => void = () => {}
  action1Symbol: Resource = $r('sys.symbol.questionmark_circle')
  action2Symbol: Resource = $r('sys.symbol.questionmark_circle')
  action3Symbol: Resource = $r('sys.symbol.questionmark_circle')

  build() {
    Row({ space: 4 }) {
      if (this.showBack) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.onBack(); })
      }

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .margin({ left: this.showBack ? 4 : 12 })

      if (this.actionCount >= 1) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.action1Symbol)
            .fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.onAction1(); })
      }
      if (this.actionCount >= 2) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.action2Symbol)
            .fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.onAction2(); })
      }
      if (this.actionCount >= 3) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.action3Symbol)
            .fontSize(22)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(40).height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.onAction3(); })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
