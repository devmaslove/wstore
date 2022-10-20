import 'package:flutter/material.dart';

import 'store.dart';

class RStoreBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store) builder;
  final List<dynamic> Function(T store) watch;
  final T? store;

  const RStoreBuilder({
    Key? key,
    required this.builder,
    required this.watch,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? RStoreWidget.store<T>(context);
    return RStoreConsumer(
      builder: (context, _) => builder(context, store),
      watch: () => watch(store),
      store: store,
    );
  }
}

class RStoreValueBuilder<T extends RStore, V> extends StatelessWidget {
  final Widget Function(BuildContext context, V value) builder;
  final V Function(T store) watch;
  final T? store;

  const RStoreValueBuilder({
    Key? key,
    this.store,
    required this.builder,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? RStoreWidget.store<T>(context);
    return RStoreConsumer(
      builder: (context, _) => builder(context, watch(store)),
      watch: () => [watch(store)],
      store: store,
    );
  }
}

/// [RStoreNamedBuilder] allows you to create widgets that can be updated
/// manually by name (see [RStore.setStore] buildersNames)
class RStoreNamedBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store) builder;
  final String name;

  const RStoreNamedBuilder({
    Key? key,
    required this.builder,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreWidget.store<T>(context);
    return RStoreConsumer(
      builder: (context, _) => builder(context, store),
      name: name,
      store: store,
    );
  }
}
