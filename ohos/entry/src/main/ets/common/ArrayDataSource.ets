// common/ArrayDataSource.ets - 通用 LazyForEach 数据源
import { IDataSource, DataChangeListener } from '@kit.ArkUI';

export class ArrayDataSource<T> implements IDataSource {
  private items: T[] = [];
  private listener: DataChangeListener | null = null;

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
    if (this.listener !== null) {
      this.listener.onDataAdd(this.items.length - 1);
    }
  }

  addDataAt(index: number, data: T): void {
    this.items.splice(index, 0, data);
    if (this.listener !== null) {
      this.listener.onDataAdd(index);
    }
  }

  setData(index: number, data: T): void {
    this.items[index] = data;
    if (this.listener !== null) {
      this.listener.onDataChange(index);
    }
  }

  deleteData(index: number): void {
    this.items.splice(index, 1);
    if (this.listener !== null) {
      this.listener.onDataDelete(index);
    }
  }

  clearData(): void {
    this.items = [];
    if (this.listener !== null) {
      this.listener.onDataReloaded();
    }
  }

  getAllData(): T[] {
    return this.items;
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener;
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    if (this.listener === listener) {
      this.listener = null;
    }
  }
}
