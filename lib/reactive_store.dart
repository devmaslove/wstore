library reactive_store;

import 'dart:async';

import 'package:flutter/material.dart';

// идея навеяна пакетом https://pub.dev/packages/consumer

bool _isWatchValuesUpdates(
  final List<dynamic> oldWatch,
  final List<dynamic> newWatch,
) {
  if (oldWatch.length == newWatch.length) {
    for (var i = 0; i < oldWatch.length; i++) {
      // TODO: need deep compare - lists, maps, sets (listEquals)
      if (oldWatch[i] != newWatch[i]) return true;
    }
  }
  return false;
}

List<dynamic> _cloneWatchList(final List<dynamic> watchList) {
  // TODO: need deep copy - lists, maps, sets
  // List newList = json.decode(json.encode(oldList));
  return [...watchList];
}

class RStore {
  late final StreamController<bool> _controllerWatchers;
  late final Stream<bool> _streamWatchers;
  late final StreamController<List<String>> _controllerTags;
  late final Stream<List<String>> _streamTags;
  final Map<String, dynamic> _composedValues = {};
  final Map<String, dynamic> _composedWatchList = {};
  final Map<String, dynamic> _composedWatchFunc = {};
  final Map<int, Timer> _timers = {};
  RStoreWidget? _widget;

  @protected
  RStoreWidget get widget {
    if (_widget == null) throw RStoreWidgetNotFoundError("Widget");
    return _widget!;
  }

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
    notifyChangeStore();
    updateBuildersByTags(tags);
  }

  /// Cache values for add to Builders watch lists:
  ///
  /// int storeValue = 1;
  /// int get composeValue => compose<int>(
  ///   getValue: () => storeValue + 1,
  ///   watch: () => [storeValue],
  ///   keyName: "composeValue",
  /// );
  @protected
  V compose<V>({
    required V Function() getValue,
    required List<dynamic> Function() watch,
    required String keyName,
  }) {
    V? value = _composedValues[keyName];
    if (value is V) return value;
    value = getValue();
    _composedValues[keyName] = value;
    _composedWatchList[keyName] = _cloneWatchList(watch());
    _composedWatchFunc[keyName] = watch;
    return value;
  }

  /// Create new timer
  ///
  /// Timers are automatically canceled when RStore.dispose
  /// or when created a new one with same timerId
  /// (сan be used to set debounce time e.g.)
  setTimer({
    required final VoidCallback onTimer,
    required final Duration duration,
    final int timerId = 0,
    final bool periodic = false,
  }) {
    // kill old timer
    killTimer(timerId: timerId);
    // create new timer
    if (periodic) {
      _timers[timerId] = Timer.periodic(duration, (_) => onTimer());
    } else {
      _timers[timerId] = Timer(duration, () {
        killTimer(timerId: timerId);
        onTimer();
      });
    }
  }

  killTimer({final int timerId = 0}) {
    _timers.remove(timerId)?.cancel();
  }

  /// Notifying builders with watchers that the store has been updated.
  @protected
  void notifyChangeStore() {
    _checkChangeComposed();
    _controllerWatchers.add(true);
  }

  /// Notifying builders with tags that the store has been updated and need
  /// rebuild.
  @protected
  void updateBuildersByTags(final List<String> tags) {
    if (tags.isNotEmpty) _controllerTags.add([...tags]);
  }

  @mustCallSuper
  void dispose() {
    // clear widget
    _widget = null;
    // clear all timers
    _timers.forEach((_, timer) {
      timer.cancel();
    });
    _timers.clear();
  }

  _checkChangeComposed() {
    final List<String> removedKeys = [];
    _composedWatchList.forEach((key, value) {
      List<dynamic> oldWatch = value;
      List<dynamic> newWatch = _composedWatchFunc[key]?.call() ?? const [];
      if (_isWatchValuesUpdates(oldWatch, newWatch)) {
        _composedValues.remove(key);
        _composedWatchFunc.remove(key);
        removedKeys.add(key);
      }
    });
    for (final key in removedKeys) {
      _composedWatchList.remove(key);
    }
  }
}

abstract class RStoreWidget<T extends RStore> extends StatefulWidget {
  const RStoreWidget({Key? key}) : super(key: key);

  @protected
  Widget build(BuildContext context, T store);

  @protected
  T createRStore();

  /// Will be called once after the widget has been mounted to RStore.
  @protected
  initRStore(T store) {}

  @override
  State<RStoreWidget<T>> createState() => _RStoreWidgetState<T>();
}

class _RStoreWidgetState<T extends RStore> extends State<RStoreWidget<T>> {
  late T store;
  bool initStore = false;

  @override
  void initState() {
    store = widget.createRStore();
    super.initState();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        store._widget = widget;
        if (!initStore) {
          initStore = true;
          widget.initRStore(store);
        }
        return _InheritedRStore<T>(
          store: store,
          constraints: constraints,
          child: widget.build(context, store),
        );
      },
    );
  }
}

class RStoreProvider<T extends RStore> extends StatefulWidget {
  final Widget child;
  final T Function() create;

  const RStoreProvider({
    Key? key,
    required this.child,
    required this.create,
  }) : super(key: key);

  @override
  State<RStoreProvider<T>> createState() => _RStoreProviderState<T>();

  /// Obtains the nearest [RStoreProvider] or [RStoreWidget] up its widget tree
  /// and returns its store.
  static T of<T extends RStore>(BuildContext context) {
    var widget = context
        .getElementForInheritedWidgetOfExactType<_InheritedRStore<T>>()
        ?.widget;
    if (widget == null) {
      throw RStoreProviderNotFoundError(T, context.widget.runtimeType);
    } else {
      return (widget as _InheritedRStore<T>).store;
    }
  }

  static BoxConstraints widgetConstraintsOf<T extends RStore>(
    BuildContext context,
  ) {
    var widget =
        context.dependOnInheritedWidgetOfExactType<_InheritedRStore<T>>();
    if (widget == null) {
      throw RStoreProviderNotFoundError(T, context.widget.runtimeType);
    } else {
      return widget.constraints;
    }
  }

  static Orientation widgetOrientationOf<T extends RStore>(
    BuildContext context,
  ) {
    var widget =
        context.dependOnInheritedWidgetOfExactType<_InheritedRStore<T>>();
    if (widget == null) {
      throw RStoreProviderNotFoundError(T, context.widget.runtimeType);
    } else {
      return widget.constraints.maxWidth > widget.constraints.maxHeight
          ? Orientation.landscape
          : Orientation.portrait;
    }
  }
}

class _RStoreProviderState<T extends RStore> extends State<RStoreProvider<T>> {
  late T store;

  @override
  void initState() {
    store = widget.create();
    super.initState();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return _InheritedRStore<T>(
        store: store,
        constraints: constraints,
        child: widget.child,
      );
    });
  }
}

class _InheritedRStore<T extends RStore> extends InheritedWidget {
  final T store;
  final BoxConstraints constraints;

  const _InheritedRStore({
    Key? key,
    required Widget child,
    required this.store,
    required this.constraints,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedRStore<T> oldWidget) {
    return oldWidget.constraints != constraints;
  }
}

/// RStoreTagBuilder allows you to create widgets that can be updated manually
/// by tag (see RStore.updateBuildersByTags)
class RStoreTagBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Widget? child)? builder;
  final Widget Function(BuildContext context)? onChange;
  final String tag;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreTagBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.store,
    required this.tag,
    this.child,
  })  : assert(tag.length > 0, 'tag must not be empty'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveTagWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, child) ?? child!;
      },
      onChange: (context) => onChange?.call(context),
      child: child,
      tag: tag,
      stream: store._streamTags,
    );
  }
}

/// RStoreContextTagBuilder allows you to create widgets that can be updated
/// manually by tag (see RStore.updateBuildersByTags)
class RStoreContextTagBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store, Widget? child)? builder;
  final Widget Function(BuildContext context, T store)? onChange;
  final String tag;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextTagBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.tag,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveTagWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, store, child) ?? child!;
      },
      onChange: (context) {
        onChange?.call(context, store);
      },
      child: child,
      tag: tag,
      stream: store._streamTags,
    );
  }
}

class _ReactiveTagWidget extends StatefulWidget {
  final Stream<List<String>> stream;
  final String tag;
  final Widget Function(BuildContext context, Widget? child) builder;
  final void Function(BuildContext context) onChange;
  final Widget? child;

  const _ReactiveTagWidget({
    required this.stream,
    required this.builder,
    required this.onChange,
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
          if (mounted) widget.onChange(context);
          if (mounted) setState(() {});
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
  final Widget Function(BuildContext context, Widget? child)? builder;
  final void Function(BuildContext context)? onChange;
  final List<dynamic> Function() watch;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.store,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, child) ?? child!;
      },
      onChange: (context) => onChange?.call(context),
      child: child,
      watch: watch,
      stream: store._streamWatchers,
    );
  }
}

class RStoreValueBuilder<V> extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    V watchVariable,
    Widget? child,
  )? builder;
  final void Function(BuildContext context, V watchVariable)? onChange;
  final V Function() watch;
  final RStore store;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreValueBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.store,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ReactiveWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, watch(), child) ?? child!;
      },
      onChange: (context) => onChange?.call(context, watch()),
      child: child,
      watch: () => [watch()],
      stream: store._streamWatchers,
    );
  }
}

class RStoreContextBuilder<T extends RStore> extends StatelessWidget {
  final Widget Function(BuildContext context, T store, Widget? child)? builder;
  final void Function(BuildContext context, T store)? onChange;
  final List<dynamic> Function(T store) watch;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, store, child) ?? child!;
      },
      onChange: (context) => onChange?.call(context, store),
      child: child,
      watch: () => watch(store),
      stream: store._streamWatchers,
    );
  }
}

class RStoreContextValueBuilder<T extends RStore, V> extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    V watchVariable,
    Widget? child,
  )? builder;
  final void Function(BuildContext context, V watchVariable)? onChange;
  final V Function(T store) watch;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreContextValueBuilder({
    Key? key,
    this.builder,
    this.onChange,
    required this.watch,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = RStoreProvider.of<T>(context);
    return _ReactiveWidget(
      builder: (context, child) {
        if (builder == null && child == null) {
          return const SizedBox.shrink();
        }
        return builder?.call(context, watch(store), child) ?? child!;
      },
      onChange: (context) => onChange?.call(context, watch(store)),
      child: child,
      watch: () => [watch(store)],
      stream: store._streamWatchers,
    );
  }
}

class _ReactiveWidget extends StatefulWidget {
  final Stream<bool> stream;
  final List<dynamic> Function() watch;
  final Widget Function(BuildContext context, Widget? child) builder;
  final void Function(BuildContext context) onChange;
  final Widget? child;

  const _ReactiveWidget({
    required this.stream,
    required this.builder,
    required this.onChange,
    required this.watch,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  _ReactiveWidgetState createState() => _ReactiveWidgetState();
}

class _ReactiveWidgetState extends State<_ReactiveWidget> {
  late StreamSubscription<bool> _setStoreSubscription;
  late List<dynamic> _lastWatch;

  @override
  void initState() {
    super.initState();

    _lastWatch = _cloneWatchList(widget.watch());
    _setStoreSubscription = widget.stream.listen((_) {
      if (_lastWatch.isNotEmpty && mounted) {
        List<dynamic> nowWatch = widget.watch();
        if (_isWatchValuesUpdates(_lastWatch, nowWatch)) {
          if (mounted) widget.onChange(context);
          if (mounted) setState(() => _lastWatch = _cloneWatchList(nowWatch));
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _setStoreSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}

/// The error that will be thrown if the RStore cannot be found in the
/// Widget tree.
class RStoreProviderNotFoundError extends Error {
  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;

  RStoreProviderNotFoundError(this.valueType, this.widgetType);

  @override
  String toString() {
    return '''Error: Could not find the correct RStoreProvider<$valueType> or RStoreWidget<$valueType> above this $widgetType Widget.

Make sure that $widgetType is under your RStoreProvider<$valueType> or RStoreWidget<$valueType>.

To fix, please add to top of your widget tree:
  RStoreProvider<$valueType>(
   create: () => $valueType(),
   child: $widgetType(...

or add to top child: YourWidget where:
  class YourWidget extends RStoreWidget<$valueType> {
   ...
''';
  }
}

class RStoreWidgetNotFoundError extends Error {
  /// The type of the value being retrieved
  final String valueType;

  RStoreWidgetNotFoundError(this.valueType);

  @override
  String toString() {
    return '''Error: Could not find ${valueType.toLowerCase()} for this RStore.

$valueType sets only in RStoreWidget.
Make sure that RStore is under your RStoreWidget.
To fix, please create RStore in RStoreWidget.

Or RStoreWidget has been unmounted, so the RState no longer has a ${valueType.toLowerCase()}
(${valueType.toLowerCase()} called after RState.dispose).
''';
  }
}
