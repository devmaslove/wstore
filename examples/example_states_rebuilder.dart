import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reactive_store/reactive_store.dart';

// https://medium.com/flutter-community/flutter-oneyearchallenge-scoped-model-vs-bloc-pattern-vs-states-rebuilder-23ba11813a4f

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RStore builder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RStoreProvider<MainPageStore>(
      store: MainPageStore(),
      child: Scaffold(
        appBar: AppBar(title: const Text('RStore builder')),
        body: const SafeArea(child: MainPageContent()),
      ),
    );
  }
}

class Item {
  int count = 0;

  static Future<List<Item>> fetchItems() async {
    return List<Item>.generate(15, (index) => Item());
  }
}

class MainPageStore extends RStore {
  List<Item> items = [];
  Color detailedColor = Colors.transparent;
  int detailedIndex = -1;

  loadItems() async {
    items = await Item.fetchItems();
    notifyChangeStore();
  }

  showDetailed(Color color, int index) {
    detailedColor = color;
    detailedIndex = index;
    notifyChangeStore();
  }

  increment() {
    int currValue = items[detailedIndex].count;
    // recreate new Item - for update watchers
    Item newItem = Item()..count = currValue + 1;
    items[detailedIndex] = newItem;
    notifyChangeStore();
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({Key? key}) : super(key: key);

  Color randomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(top: 10),
          height: 150,
          child: RStoreContextBuilder<MainPageStore>(
            watch: (store) => [store.items],
            builder: (context, store, _) => store.items.isEmpty
                ? Center(
                    child: Container(),
                    // child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.items.length,
                    itemBuilder: (context, index) {
                      Color randColor = randomColor();
                      return SizedBox(
                        width: 100,
                        child: RStoreValueBuilder<Item>(
                            store: store,
                            watch: () => store.items[index],
                            builder: (context, item, _) {
                              return ItemCard(
                                item: item,
                                color: randColor,
                                onTap: () =>
                                    RStoreProvider.of<MainPageStore>(context)
                                        .showDetailed(randColor, index),
                              );
                            }),
                      );
                    },
                  ),
          ),
        ),
        const Divider(),
        Center(
          child: RStoreContextBuilder<MainPageStore>(
            watch: (store) => [store.detailedIndex, store.detailedColor],
            builder: (context, store, _) => store.detailedIndex < 0
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: ItemCard(
                      item: Item(),
                      color: randomColor(),
                      onTap: () => store.loadItems(),
                    ),
                  )
                : SizedBox(
                    width: 200,
                    height: 200,
                    child: RStoreValueBuilder<Item>(
                        store: store,
                        watch: () => store.items[store.detailedIndex],
                        builder: (context, item, _) {
                          return ItemCard(
                            item: item,
                            color: store.detailedColor,
                            onTap: () => store.increment(),
                          );
                        }),
                  ),
          ),
        ),
      ],
    );
  }
}

class ItemCard extends StatelessWidget {
  final Item item;
  final Color color;
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: color,
        child: Center(
          child: Text(
            '${item.count}',
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }
}
