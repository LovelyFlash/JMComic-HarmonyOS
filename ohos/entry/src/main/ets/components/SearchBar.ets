// components/SearchBar.ets - 搜索栏组件
@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索漫画...'
  @Prop keyword: string = ''
  onSearch: (keyword: string) => void = () => {}
  onTextChanged: (text: string) => void = () => {}
  private inputController: TextInputController = new TextInputController()

  build() {
    Row() {
      Text('🔍')
        .fontSize(16)
        .margin({ right: 8 })
      TextInput({ placeholder: this.placeholder, controller: this.inputController })
        .layoutWeight(1)
        .height(36)
        .fontSize(14)
        .backgroundColor('transparent')
        .onChange((value: string) => {
          this.onTextChanged(value);
        })
        .onSubmit(() => {
          this.onSearch(this.keyword);
        })
      if (this.keyword.length > 0) {
        Text('×')
          .fontSize(18)
          .fontColor('#999999')
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
  }
}
