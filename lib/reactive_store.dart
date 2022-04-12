library reactive_store;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// идея взята из https://pub.dev/packages/consumer

// TODO: Добавить метод computed который будет кешировать
// значения которые от него зависят, что-то типа
// int get total => computed((){ return this.valueA + this.valueB; }, [this.valueA, this.valueB]);
// она будет кешировать результат - чтобы ссылка не менялась

class RStore {
  late StreamController _controllerWatchers;
  late Stream _streamWatchers;
  late StreamController<List<String>> _controllerTags;
  late Stream<List<String>> _streamTags;

  Stream get streamChangeStore => _streamWatchers;

  Stream<List<String>> get streamUpdateByTags => _streamTags;

  /// Creates a reactive store.
  RStore() {
    _controllerWatchers = StreamController.broadcast();
    _streamWatchers = _controllerWatchers.stream;
    _controllerTags = StreamController<List<String>>.broadcast();
    _streamTags = _controllerTags.stream;
  }

  /// Notifying that the store has been updated.
  void setStore(VoidCallback fn, {final List<String> tags = const []}) {
    fn();
    // TODO: add param - debounceDelay : 400
    notifyChangeStore();
    updateBuildersByTags(tags);
  }

  /// Notifying builders with watchers that the store has been updated.
  @protected
  void notifyChangeStore() {
    _controllerWatchers.add(this);
  }

  /// Notifying builders with tags that the store has been updated and need
  /// rebuild.
  @protected
  void updateBuildersByTags(final List<String> tags) {
    if (tags.isNotEmpty) _controllerTags.add([...tags]);
  }

  @mustCallSuper
  void dispose() {}
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

/// RStoreTagBuilder allows you to create widgets that can be updated manually
/// by tag (see RStore.updateBuildersByTags)
class RStoreTagBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final String tag;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreTagBuilder({
    Key? key,
    required this.builder,
    required this.store,
    required this.tag,
    this.child,
  })  : assert(tag.length > 0, 'tag must not be empty'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveTagWidget(
      builder: builder,
      child: child,
      tag: tag,
      stream: store.streamUpdateByTags,
    );
  }
}

/// RStoreContextTagBuilder allows you to create widgets that can be updated
/// manually by tag (see RStore.updateBuildersByTags)
class RStoreContextTagBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store, Widget? child) builder;
  final String tag;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextTagBuilder({
    Key? key,
    required this.builder,
    required this.tag,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveTagWidget(
      builder: (context, child) {
        return builder(context, store, child);
      },
      child: child,
      tag: tag,
      stream: store.streamUpdateByTags,
    );
  }
}

class _ReactiveTagWidget extends StatefulWidget {
  final Stream<List<String>> stream;
  final String tag;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _ReactiveTagWidget({
    required this.stream,
    required this.builder,
    required this.tag,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  _ReactiveTagWidgetState createState() => _ReactiveTagWidgetState();
}

class _ReactiveTagWidgetState extends State<_ReactiveTagWidget> {
  late StreamSubscription<List<String>> _changeStoreSubscription;

  @override
  void initState() {
    super.initState();
    _changeStoreSubscription = widget.stream.listen((tags) {
      if (mounted) {
        if (tags.contains(widget.tag)) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _changeStoreSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

class RStoreBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final List<dynamic> Function() watch;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreBuilder({
    Key? key,
    required this.builder,
    required this.store,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: builder,
      child: child,
      watch: watch,
      stream: store.streamChangeStore,
    );
  }
}

class RStoreValueBuilder<V> extends StatelessWidget {
  final Widget Function(BuildContext context, V watchVariable, Widget? child)
      builder;
  final V Function() watch;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreValueBuilder({
    Key? key,
    required this.builder,
    required this.store,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: (context, child) {
        return builder(context, watch(), child);
      },
      child: child,
      watch: () => [watch()],
      stream: store.streamChangeStore,
    );
  }
}

class RStoreContextBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store, Widget? child) builder;
  final List<dynamic> Function(T store) watch;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextBuilder({
    Key? key,
    required this.builder,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context, child) {
        return builder(context, store, child);
      },
      child: child,
      watch: () => watch(store),
      stream: store.streamChangeStore,
    );
  }
}

class RStoreContextValueBuilder<T extends RStore, V> extends StatelessWidget {
  final Widget Function(BuildContext context, V watchVariable, Widget? child)
      builder;
  final V Function(T store) watch;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextValueBuilder({
    Key? key,
    required this.builder,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context, child) {
        return builder(context, watch(store), child);
      },
      child: child,
      watch: () => [watch(store)],
      stream: store.streamChangeStore,
    );
  }
}

class _ReactiveWidget extends StatefulWidget {
  final Stream stream;
  final List<dynamic> Function() watch;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _ReactiveWidget({
    required this.stream,
    required this.builder,
    required this.watch,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  _ReactiveWidgetState createState() => _ReactiveWidgetState();
}

class _ReactiveWidgetState extends State<_ReactiveWidget> {
  late StreamSubscription _setStoreSubscription;
  late List<dynamic> _lastWatch;

  @override
  void initState() {
    super.initState();

    _lastWatch = _cloneWatchList(widget.watch());
    _setStoreSubscription = widget.stream.listen((_) {
      if (_lastWatch.isNotEmpty && mounted) {
        List<dynamic> nowWatch = widget.watch();
        if (_isWatchValuesUpdates(nowWatch)) {
          setState(() => _lastWatch = _cloneWatchList(nowWatch));
        }
      }
    });
  }

  bool _isWatchValuesUpdates(final List<dynamic> newWatch) {
    assert(_lastWatch.length == newWatch.length);
    for (var i = 0; i < _lastWatch.length; i++) {
      // TODO: need deep compare - lists, maps, sets (listEquals)
      if (_lastWatch[i] != newWatch[i]) return true;
    }
    return false;
  }

  List<dynamic> _cloneWatchList(final List<dynamic> watchList) {
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
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}
