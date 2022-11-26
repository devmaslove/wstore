import 'package:flutter_test/flutter_test.dart';
import 'package:wstore/wstore.dart';

class TestValue {
  final String value;

  // not cost constructor for testing identical
  TestValue(this.value);
}

class WStoreTest extends WStore {
  String hello = '';

  TestValue get nameFromFuture => computedFromFuture(
        future: Future.value(TestValue('Harry')),
        initialData: TestValue('?'),
        keyName: 'nameFromFuture',
      );

  TestValue get lastNameFromStream => computedFromStream(
        stream: Stream.value(TestValue('Potter')),
        initialData: TestValue('?'),
        keyName: 'lastNameFromStream',
      );

  TestValue get sayHello => computed(
        getValue: () => TestValue("$hello, friends"),
        watch: () => [hello],
        keyName: 'sayHello',
      );

  String get nameFromConverter => computedConverter<TestValue, String>(
        future: Future.value(TestValue('Harry')),
        getValue: (name) => name.value,
        initialValue: '',
        keyName: 'nameFromConverter',
      );

  String get lastNameFromConverter => computedConverter<TestValue, String>(
        stream: Stream.value(TestValue('Potter')),
        getValue: (lastName) => lastName.value,
        initialValue: '',
        keyName: 'lastNameFromConverter',
      );

  String get fullNameFromConverter2 =>
      computedConverter2<TestValue, TestValue, String>(
        futureA: Future.value(TestValue('Harry')),
        streamB: Stream.value(TestValue('Potter')),
        getValue: (firstName, lastName) =>
            '${firstName.value} ${lastName.value}',
        initialValue: '',
        keyName: 'fullNameFromStream',
      );

  String get sayHelloWithName => computed(
        getValue: () => "${sayHello.value}, I'm ${nameFromFuture.value}",
        watch: () => [sayHello, nameFromFuture],
        keyName: 'sayHelloWithName',
      );
}

void main() {
  test('WStore computed works', () {
    final store = WStoreTest();

    // test same computed values are identical
    TestValue valueFirstCall = store.sayHello;
    TestValue valueSecondCall = store.sayHello;
    expect(identical(valueFirstCall, valueSecondCall), true);

    // test set linked computed field
    expect(store.sayHello.value, equals(", friends"));
    expect(store.sayHelloWithName, equals(", friends, I'm ?"));
    store.setStore(() {
      store.hello = 'Hello';
    });
    expect(store.sayHello.value, equals("Hello, friends"));
    expect(store.sayHelloWithName, equals("Hello, friends, I'm ?"));

    // test set computed from future
    expect(store.nameFromFuture.value, equals("?"));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.nameFromFuture.value,
      ),
      completion(equals("Harry")),
    );

    // test set nested computed - links computed from future
    expect(store.sayHelloWithName, equals("Hello, friends, I'm ?"));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.sayHelloWithName,
      ),
      completion(equals("Hello, friends, I'm Harry")),
    );

    // test set computed from stream
    expect(store.lastNameFromStream.value, equals("?"));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.lastNameFromStream.value,
      ),
      completion(equals("Potter")),
    );

    // test set computed from converter with future
    expect(store.nameFromConverter, equals(""));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.nameFromConverter,
      ),
      completion(equals("Harry")),
    );

    // test set computed from converter with stream
    expect(store.lastNameFromConverter, equals(""));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.lastNameFromConverter,
      ),
      completion(equals("Potter")),
    );

    // test set computed from converter2
    expect(store.fullNameFromConverter2, equals(""));
    expect(
      Future.delayed(
        const Duration(milliseconds: 100),
        () => store.fullNameFromConverter2,
      ),
      completion(equals("Harry Potter")),
    );
  });
}
