import 'package:flutter/material.dart';

import 'status.dart';
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
/// manually by name (see [WStore.notifyChangeNamed])
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

class WStoreStatusBuilder<T extends WStore> extends StatelessWidget {
  final WStoreStatus Function(T store) watch;
  final T? store;
  final Widget Function(BuildContext context, WStoreStatus status) builder;
  final Widget Function(BuildContext context)? builderInit;
  final Widget Function(BuildContext context)? builderLoading;
  final Widget Function(BuildContext context)? builderLoaded;
  final Widget Function(BuildContext context)? builderError;
  final void Function(BuildContext context)? onStatusInit;
  final void Function(BuildContext context)? onStatusLoading;
  final void Function(BuildContext context)? onStatusLoaded;
  final void Function(BuildContext context)? onStatusError;

  const WStoreStatusBuilder({
    Key? key,
    required this.watch,
    this.store,
    required this.builder,
    this.builderInit,
    this.builderLoading,
    this.builderLoaded,
    this.builderError,
    this.onStatusInit,
    this.onStatusLoading,
    this.onStatusLoaded,
    this.onStatusError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = this.store ?? WStoreWidget.store<T>(context);
    return WStoreConsumer(
      builder: (context, _) => _statusBuilder(context, watch(store)),
      onChange: (context) => _statusChange(context, watch(store)),
      watch: () => [watch(store)],
      store: store,
    );
  }

  Widget _statusBuilder(BuildContext context, final WStoreStatus status) {
    switch (status) {
      case WStoreStatus.init:
        if (builderInit != null) return builderInit!.call(context);
        break;
      case WStoreStatus.loading:
        if (builderLoading != null) return builderLoading!.call(context);
        break;
      case WStoreStatus.loaded:
        if (builderLoaded != null) return builderLoaded!.call(context);
        break;
      case WStoreStatus.error:
        if (builderError != null) return builderError!.call(context);
        break;
    }
    return builder(context, status);
  }

  void _statusChange(BuildContext context, final WStoreStatus status) {
    switch (status) {
      case WStoreStatus.init:
        onStatusInit?.call(context);
        break;
      case WStoreStatus.loading:
        onStatusLoading?.call(context);
        break;
      case WStoreStatus.loaded:
        onStatusLoaded?.call(context);
        break;
      case WStoreStatus.error:
        onStatusError?.call(context);
        break;
    }
  }
}
