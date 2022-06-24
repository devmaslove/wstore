import 'package:flutter/material.dart';
import 'package:reactive_store/reactive_store.dart';

class CounterPageStore extends RStore {
  int counter = 0;

  void incrementCounter() {
    setStore(() {
      counter++;
    });
  }
}

class CounterPage extends RStoreWidget<CounterPageStore> {
  const CounterPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, CounterPageStore store) {
    return Scaffold(
      appBar: AppBar(
        title: RStoreValueBuilder<int>(
            store: store,
            watch: () => store.counter,
            builder: (context, counter, _) {
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
  CounterPageStore createRStore() => CounterPageStore();
}

class CountText extends StatelessWidget {
  const CountText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RStoreContextValueBuilder<CounterPageStore, int>(
      watch: (store) => store.counter,
      builder: (context, counter, _) {
        return Text(
          '$counter',
          style: Theme.of(context).textTheme.headline4,
        );
      },
    );
  }
}
