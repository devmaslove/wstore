import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rstore/rstore.dart';
import 'package:url_launcher/url_launcher.dart';

class Item {
  int count = 0;
  final Color color;

  Item(this.color);

  static Future<List<Item>> fetchItems() async {
    return List<Item>.generate(15, (index) => Item(_randomColor()));
  }

  static Color _randomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }
}

class StatesReBuilderPageStore extends RStore {
  static const _timerIdLoadItems = 0;
  List<Item> items = [];
  int detailedIndex = -1;

  loadItems() {
    setTimeout(() async {
      items = await Item.fetchItems();
      setStore(() {});
    }, 2500, _timerIdLoadItems);
  }

  showDetailed(int index) {
    setStore(() => detailedIndex = index);
  }

  increment() {
    int currValue = items[detailedIndex].count;
    Color currColor = items[detailedIndex].color;
    // recreate new Item - for update watchers
    Item newItem = Item(currColor)..count = currValue + 1;
    items[detailedIndex] = newItem;
    setStore(() {});
  }
}

class StatesReBuilderPage extends RStoreWidget<StatesReBuilderPageStore> {
  const StatesReBuilderPage({Key? key}) : super(key: key);

  @override
  void initRStore(StatesReBuilderPageStore store) => store.loadItems();

  @override
  Widget build(BuildContext context, StatesReBuilderPageStore store) {
    return Scaffold(
      appBar: AppBar(title: const Text('States re-builder')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10),
            height: 150,
            child: RStoreValueBuilder<StatesReBuilderPageStore, List<Item>>(
              store: store,
              watch: (store) => store.items,
              builder: (context, items) => items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 100,
                            child: RStoreValueBuilder<StatesReBuilderPageStore,
                                Item>(
                              store: store,
                              watch: (store) => store.items[index],
                              builder: (context, item) {
                                return ItemCard(
                                  item: item,
                                  onTap: () => store.showDetailed(index),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(),
          Center(
            child: RStoreValueBuilder<StatesReBuilderPageStore, int>(
              store: store,
              watch: (store) => store.detailedIndex,
              builder: (context, index) => index < 0
                  ? SizedBox(
                      width: 200,
                      height: 200,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                        ),
                        child: const Center(
                          child: Text(
                            'Select card',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 38),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 200,
                      height: 200,
                      child: RStoreValueBuilder<StatesReBuilderPageStore, Item>(
                        store: store,
                        watch: (store) => store.items[store.detailedIndex],
                        builder: (context, item) {
                          return ItemCard(
                            item: item,
                            onTap: () => store.increment(),
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async {
              final url = Uri.parse(
                  'https://medium.com/flutter-community/flutter-oneyearchallenge-scoped-model-vs-bloc-pattern-vs-states-rebuilder-23ba11813a4f');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: const Text('More info on medium'),
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
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: item.color,
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
