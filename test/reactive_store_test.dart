import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_store/reactive_store.dart';

class RStoreTest extends RStore {
  int counter = 0;
  String title = '';
}

void main() {
  test('RStore emitted event on setStore', () {
    final store = RStoreTest();
    store.streamChangeStore.listen((event) {
      expectAsync1((event) {
        expect(event, store);
      });
    });
    store.setStore(() {
      store.counter++;
      store.title = 'test';
    });
  });
}
