import { describe, it, expect } from '@ohos/hypium';
import { ArrayDataSource } from '../main/ets/common/ArrayDataSource';

class FakeListener implements DataChangeListener {
  reloaded: number = 0;
  added: number[] = [];
  changed: number[] = [];
  deleted: number[] = [];

  onDataReloaded(): void {
    this.reloaded++;
  }

  onDataAdd(index: number): void {
    this.added.push(index);
  }

  onDataMove(from: number, to: number): void {
  }

  onDataDelete(index: number): void {
    this.deleted.push(index);
  }

  onDataChange(index: number): void {
    this.changed.push(index);
  }

  onDatasetChange(operations: DataOperation[]): void {
  }

  onDataAdded(index: number): void {
  }

  onDataMoved(from: number, to: number): void {
  }

  onDataDeleted(index: number): void {
  }

  onDataChanged(index: number): void {
  }
}

export default function arrayDataSourceTest() {
  describe('ArrayDataSource', () => {
    it('adds_all_items_and_notifies_each_index', 0, () => {
      const source = new ArrayDataSource<number>([1, 2]);
      const listener = new FakeListener();
      source.registerDataChangeListener(listener);
      source.addAll([3, 4, 5]);
      expect(source.totalCount()).assertEqual(5);
      expect(listener.added.length).assertEqual(3);
      expect(listener.added[0]).assertEqual(2);
      expect(listener.added[1]).assertEqual(3);
      expect(listener.added[2]).assertEqual(4);
    });

    it('replace_and_clear_use_reload', 0, () => {
      const source = new ArrayDataSource<number>([1]);
      const listener = new FakeListener();
      source.registerDataChangeListener(listener);
      source.replaceAll([7, 8]);
      expect(source.totalCount()).assertEqual(2);
      expect(source.getData(0)).assertEqual(7);
      expect(listener.reloaded).assertEqual(1);
      source.clearData();
      expect(source.totalCount()).assertEqual(0);
      expect(listener.reloaded).assertEqual(2);
    });
  });
}
