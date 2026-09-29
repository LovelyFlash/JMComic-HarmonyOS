// common/ArrayDataSource.ets - LazyForEach 数据源

export class ArrayDataSource<T> implements IDataSource {
  private items: T[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: T[] = []) {
    this.items = data;
  }

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): T {
    return this.items[index];
  }

  addData(data: T): void {
    this.items.push(data);
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataAdd(this.items.length - 1);
    }
  }

  addAll(data: T[]): void {
    const start = this.items.length;
    for (let i = 0; i < data.length; i++) {
      this.items.push(data[i]);
    }
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataAdd(start);
    }
  }

  setData(index: number, data: T): void {
    this.items[index] = data;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataChange(index);
    }
  }

  deleteData(index: number): void {
    this.items.splice(index, 1);
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataDelete(index);
    }
  }

  clearData(): void {
    this.items = [];
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }

  getAllData(): T[] {
    return this.items;
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }
}
