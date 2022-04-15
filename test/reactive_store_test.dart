import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_store/reactive_store.dart';

class RStoreTest extends RStore {
  String hello = '';

  get sayHello => compose<String>(
        getValue: () => hello + " World",
        watch: () => [hello],
        keyName: 'sayHello',
      );
}

void main() {
  test('RStore compose works', () {
    final store = RStoreTest();

    String say1 = store.sayHello;
    expect(say1, equals(" World"));

    String say2 = store.sayHello;
    expect(identical(say1, say2), true);

    store.setStore(() {
      store.hello = 'Hello';
    });
    String say3 = store.sayHello;
    expect(say3, equals("Hello World"));
  });
}
