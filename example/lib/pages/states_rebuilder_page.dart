import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reactive_store/reactive_store.dart';

// https://medium.com/flutter-community/flutter-oneyearchallenge-scoped-model-vs-bloc-pattern-vs-states-rebuilder-23ba11813a4f

class Item {
  int count = 0;

  static Future<List<Item>> fetchItems() async {
    return List<Item>.generate(15, (index) => Item());
  }
}

class StatesReBuilderPageStore extends RStore {
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

  Color randomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }
}

class StatesReBuilderPage extends RStoreWidget<StatesReBuilderPageStore> {
  const StatesReBuilderPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, StatesReBuilderPageStore store) {
    return Scaffold(
      appBar: AppBar(title: const Text('States re-builder')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10),
            height: 150,
            child: RStoreValueBuilder<List<Item>>(
              store: store,
              watch: () => store.items,
              builder: (context, items, _) => items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        Color randColor = store.randomColor();
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
                                    store.showDetailed(randColor, index),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(),
          Center(
            child: RStoreBuilder(
              store: store,
              watch: () => [store.detailedIndex, store.detailedColor],
              builder: (context, _) => store.detailedIndex < 0
                  ? SizedBox(
                      width: 200,
                      height: 200,
                      child: ItemCard(
                        item: Item(),
                        color: store.randomColor(),
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
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  StatesReBuilderPageStore createRStore() => StatesReBuilderPageStore();
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
