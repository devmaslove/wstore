import 'package:flutter/material.dart';

import 'store.dart';

class WStoreListener<T extends WStore> extends StatelessWidget {
  final List<dynamic> Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, T store) onChange;

  const WStoreListener({
    Key? key,
    required this.watch,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) => onChange(context, store),
      store: store,
      child: child,
    );
  }
}

class WStoreValueListener<T extends WStore, V> extends StatelessWidget {
  final V Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, V value) onChange;

  const WStoreValueListener({
    Key? key,
    required this.watch,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) => onChange(context, watch(store)),
      store: store,
      child: child,
    );
  }
}

/// [WStoreNamedListener] allows you to create listener that can be changed
/// manually by name (see [WStore.setStore] buildersNames)
class WStoreNamedListener<T extends WStore> extends StatelessWidget {
  final String name;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, T store) onChange;

  const WStoreNamedListener({
    Key? key,
    required this.name,
    required this.onChange,
    required this.child,
    this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      name: name,
      onChange: (context) => onChange(context, store),
      store: store,
      child: child,
    );
  }
}

class WStoreBoolListener<T extends WStore> extends StatelessWidget {
  final bool Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context)? onTrue;
  final void Function(BuildContext context)? onFalse;
  final void Function(T store)? reset;

  const WStoreBoolListener({
    Key? key,
    required this.watch,
    this.onTrue,
    this.onFalse,
    required this.child,
    this.store,
    this.reset,
  })  : assert(
            onTrue != null || onFalse != null, 'onTrue or onFalse must be set'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) {
        final bool value = watch(store);
        if (value) {
          if (reset != null) {
            store.setStore(() => reset!(store));
          }
          onTrue?.call(context);
        } else {
          onFalse?.call(context);
        }
      },
      store: store,
      child: child,
    );
  }
}

class WStoreStringListener<T extends WStore> extends StatelessWidget {
  final String Function(T store) watch;
  final Widget child;
  final T? store;
  final void Function(BuildContext context, String value)? onNotEmpty;
  final void Function(BuildContext context)? onEmpty;
  final void Function(T store)? reset;

  const WStoreStringListener({
    Key? key,
    required this.watch,
    this.onNotEmpty,
    this.onEmpty,
    required this.child,
    this.store,
    this.reset,
  })  : assert(onNotEmpty != null || onEmpty != null,
            'onEmpty or onNotEmpty must be set'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      watch: () => [watch(store)],
      onChange: (context) {
        final String value = watch(store);
        if (value.isNotEmpty) {
          if (reset != null) {
            store.setStore(() => reset!(store));
          }
          onNotEmpty?.call(context, value);
        } else {
          onEmpty?.call(context);
        }
      },
      store: store,
      child: child,
    );
  }
}
