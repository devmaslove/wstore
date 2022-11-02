import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class CounterPageStore extends WStore {
  int counter = 0;

  void incrementCounter() {
    setStore(() {
      // This call to setStore tells the WStoreBuilders that something has
      // changed in this WStore, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // counter without calling setStore(), then the build method would not be
      // called again, and so nothing would appear to happen.
      counter++;
    });
  }
}

class CounterPage extends WStoreWidget<CounterPageStore> {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, CounterPageStore store) {
    return Scaffold(
      appBar: AppBar(
        title: WStoreValueBuilder<CounterPageStore, int>(
            store: store,
            watch: (store) => store.counter,
            builder: (context, counter) {
              return Text('Counter: $counter');
            }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('You have pushed the button this many times:'),
            CountText(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => store.incrementCounter(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  CounterPageStore createWStore() => CounterPageStore();
}

class CountText extends StatelessWidget {
  const CountText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WStoreValueBuilder<CounterPageStore, int>(
      watch: (store) => store.counter,
      builder: (context, counter) {
        return Text(
          '$counter',
          style: Theme.of(context).textTheme.headline4,
        );
      },
    );
  }
}
