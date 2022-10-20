import 'package:flutter/material.dart';

import 'store.dart';

class RStoreListener<T extends RStore> extends StatelessWidget {
  final List<dynamic> Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, T store) onChange;

  const RStoreListener({
    Key? key,
    required this.watch,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? RStoreWidget.store<T>(context);
    return RStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) => onChange(context, store),
      child: child,
      store: store,
    );
  }
}

class RStoreValueListener<T extends RStore, V> extends StatelessWidget {
  final V Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, V value) onChange;

  const RStoreValueListener({
    Key? key,
    required this.watch,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? RStoreWidget.store<T>(context);
    return RStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) => onChange(context, watch(store)),
      child: child,
      store: store,
    );
  }
}

/// [RStoreNamedListener] allows you to create listener that can be changed
/// manually by name (see [RStore.setStore] buildersNames)
class RStoreNamedListener<T extends RStore> extends StatelessWidget {
  final String name;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, T store) onChange;

  const RStoreNamedListener({
    Key? key,
    required this.name,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? RStoreWidget.store<T>(context);
    return RStoreConsumer(
      name: name,
      onChange: (context) => onChange(context, store),
      child: child,
      store: store,
    );
  }
}
