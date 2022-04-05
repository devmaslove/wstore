library reactive_store;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// идея взята из https://pub.dev/packages/consumer
// https://medium.com/flutter-community/flutter-oneyearchallenge-scoped-model-vs-bloc-pattern-vs-states-rebuilder-23ba11813a4f

typedef WatchList = List<dynamic>;

class RStore {
  late StreamController _controller;
  late Stream _stream;

  /// Creates a reactive store.
  RStore() {
    _controller = StreamController.broadcast();
    _stream = _controller.stream;
  }

  Stream get streamChangeStore => _stream;

  /// Notifying watchers that the store has been updated.
  void setStore([Function()? fn]) {
    fn?.call();
    // TODO: add param - tags : ['Text', 'Text2'] (для обновления конкретных билдеров)
    // TODO: add param - debounceDelay : 400
    // notify watchers
    _controller.add(this);
  }

  @protected
  @mustCallSuper
  void dispose() {}
}

// TODO: Сделать RStoreTagBuilder - чтобы обновлять не по watch а по tag
// это позволит вручную обновлять нужные виджеты

class RStoreBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final WatchList Function() watch;
  final RStore store;

  const RStoreBuilder({
    Key? key,
    required this.builder,
    required this.store,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: builder,
      watch: watch,
      stream: store.streamChangeStore,
    );
  }
}

class RStoreValueBuilder<V> extends StatelessWidget {
  final Widget Function(BuildContext context, V watchVariable) builder;
  final V Function() watch;
  final RStore store;

  const RStoreValueBuilder({
    Key? key,
    required this.builder,
    required this.store,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: (context) {
        return builder(context, watch());
      },
      watch: () => [watch()],
      stream: store.streamChangeStore,
    );
  }
}

class RStoreContextBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store) builder;
  final WatchList Function(T store) watch;

  const RStoreContextBuilder({
    Key? key,
    required this.builder,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context) {
        return builder(context, store);
      },
      watch: () => watch(store),
      stream: store.streamChangeStore,
    );
  }
}

class RStoreContextValueBuilder<T extends RStore, V> extends StatelessWidget {
  final Widget Function(BuildContext context, V watchVariable) builder;
  final V Function(T store) watch;

  const RStoreContextValueBuilder({
    Key? key,
    required this.builder,
    required this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context) {
        return builder(context, watch(store));
      },
      watch: () => [watch(store)],
      stream: store.streamChangeStore,
    );
  }
}

class RStoreProvider<T extends RStore> extends StatelessWidget {
  final Widget child;
  final T store;

  const RStoreProvider({
    Key? key,
    required this.child,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      create: (_) => store,
      dispose: (_, __) => store.dispose(),
      lazy: false,
      child: child,
    );
  }

  /// Obtains the nearest [RStoreProvider<T>] up its widget tree and returns its
  /// store.
  static T of<T>(BuildContext context) {
    return Provider.of<T>(context, listen: false);
  }
}

class _ReactiveWidget extends StatefulWidget {
  final Stream stream;
  final WatchList Function() watch;
  final Widget Function(BuildContext context) builder;

  const _ReactiveWidget({
    required this.stream,
    required this.builder,
    required this.watch,
    Key? key,
  }) : super(key: key);

  @override
  _ReactiveWidgetState createState() => _ReactiveWidgetState();
}

class _ReactiveWidgetState extends State<_ReactiveWidget> {
  late StreamSubscription _setStoreSubscription;
  late WatchList _lastWatch;

  @override
  void initState() {
    super.initState();

    _lastWatch = _cloneWatchList(widget.watch());
    _setStoreSubscription = widget.stream.listen((_) {
      if (_lastWatch.isNotEmpty && mounted) {
        WatchList nowWatch = widget.watch();
        if (_isWatchValuesUpdates(nowWatch)) {
          setState(() => _lastWatch = _cloneWatchList(nowWatch));
        }
      }
    });
  }

  bool _isWatchValuesUpdates(final WatchList newWatch) {
    assert(_lastWatch.length == newWatch.length);
    for (var i = 0; i < _lastWatch.length; i++) {
      // TODO: need deep compare - lists, maps, sets (listEquals)
      if (_lastWatch[i] != newWatch[i]) return true;
    }
    return false;
  }

  WatchList _cloneWatchList(final WatchList watchList) {
    // TODO: need deep copy - lists, maps, sets
    // List newList = json.decode(json.encode(oldList));
    return [...watchList];
  }

  @override
  void dispose() {
    super.dispose();
    _setStoreSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
