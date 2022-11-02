import 'package:flutter/material.dart';

import 'store.dart';

class WStoreBuilder<T extends WStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store) builder;
  final List<dynamic> Function(T store) watch;
  final T? store;

  const WStoreBuilder({
    Key? key,
    required this.builder,
    required this.watch,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      builder: (context, _) => builder(context, store),
      watch: () => watch(store),
      store: store,
    );
  }
}

class WStoreValueBuilder<T extends WStore, V> extends StatelessWidget {
  final Widget Function(BuildContext context, V value) builder;
  final V Function(T store) watch;
  final T? store;

  const WStoreValueBuilder({
    Key? key,
    this.store,
    required this.builder,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      builder: (context, _) => builder(context, watch(store)),
      watch: () => [watch(store)],
      store: store,
    );
  }
}

/// [WStoreNamedBuilder] allows you to create widgets that can be updated
/// manually by name (see [WStore.setStore] buildersNames)
class WStoreNamedBuilder<T extends WStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store) builder;
  final String name;

  const WStoreNamedBuilder({
    Key? key,
    required this.builder,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = WStoreWidget.store<T>(context);
    return WStoreConsumer(
      builder: (context, _) => builder(context, store),
      name: name,
      store: store,
    );
  }
}
