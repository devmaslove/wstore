import 'dart:async';

import 'package:flutter/material.dart';

import 'error.dart';
import 'inherited.dart';

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
    if (_widget == null) {
      throw RStoreNotFoundError(RStore, RStoreWidget, "Widget");
    }
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
  void setTimer({
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

  /// Create new non periodic timer
  ///
  /// Timers are automatically canceled when RStore.dispose
  /// or when created a new one with same timerId
  /// (сan be used to set debounce time e.g.)
  void setTimeout(VoidCallback onTimer, int milliseconds, [int timerId = 0]) {
    setTimer(
      onTimer: onTimer,
      duration: Duration(milliseconds: milliseconds),
      timerId: timerId,
    );
  }

  void killTimer({final int timerId = 0}) {
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

  void _checkChangeComposed() {
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

  static bool _isWatchValuesUpdates(
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

  static List<dynamic> _cloneWatchList(final List<dynamic> watchList) {
    // TODO: need deep copy - lists, maps, sets
    // List newList = json.decode(json.encode(oldList));
    return [...watchList];
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
  void initRStore(T store) {}

  @override
  State<RStoreWidget<T>> createState() => _RStoreWidgetState<T>();

  /// Obtains the nearest [RStoreWidget] up its widget tree
  /// and returns its store.
  static T of<T extends RStore>(BuildContext context) {
    var widget = context
        .getElementForInheritedWidgetOfExactType<InheritedRStore<T>>()
        ?.widget;
    if (widget == null) {
      throw RStoreNotFoundError(T, context.widget.runtimeType, '');
    } else {
      return (widget as InheritedRStore<T>).store;
    }
  }

  static BoxConstraints widgetConstraintsOf<T extends RStore>(
    BuildContext context,
  ) {
    var widget =
        context.dependOnInheritedWidgetOfExactType<InheritedRStore<T>>();
    if (widget == null) {
      throw RStoreNotFoundError(T, context.widget.runtimeType, '');
    } else {
      return widget.constraints;
    }
  }

  static Orientation widgetOrientationOf<T extends RStore>(
    BuildContext context,
  ) {
    var widget =
        context.dependOnInheritedWidgetOfExactType<InheritedRStore<T>>();
    if (widget == null) {
      throw RStoreNotFoundError(T, context.widget.runtimeType, '');
    } else {
      return widget.constraints.maxWidth > widget.constraints.maxHeight
          ? Orientation.landscape
          : Orientation.portrait;
    }
  }
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
        return InheritedRStore<T>(
          store: store,
          constraints: constraints,
          child: widget.build(context, store),
        );
      },
    );
  }
}

class RStoreBuilder extends StatefulWidget {
  final RStore store;
  final List<dynamic> Function()? watch;
  final String? tag;
  final Widget Function(BuildContext context, Widget? child)? builder;
  final void Function(BuildContext context)? onChange;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreBuilder({
    required this.store,
    this.builder,
    this.onChange,
    this.watch,
    this.tag,
    this.child,
    Key? key,
  })  : assert(tag == null || tag.length > 0, 'tag must not be empty string'),
        super(key: key);

  @override
  _RStoreBuilderState createState() => _RStoreBuilderState();
}

class _RStoreBuilderState extends State<RStoreBuilder> {
  StreamSubscription<List<String>>? _changeStoreSubscription;
  StreamSubscription<bool>? _setStoreSubscription;
  List<dynamic> _lastWatch = [];

  @override
  void initState() {
    super.initState();

    if (widget.tag != null) {
      _changeStoreSubscription = widget.store._streamTags.listen((tags) {
        if (mounted) {
          if (tags.contains(widget.tag)) {
            widget.onChange?.call(context);
            // check mounted because onChange can unmount
            if (mounted && widget.builder != null) setState(() {});
          }
        }
      });
    }

    if (widget.watch != null) {
      _lastWatch = RStore._cloneWatchList(widget.watch!());
      _setStoreSubscription = widget.store._streamWatchers.listen((_) {
        if (_lastWatch.isNotEmpty && mounted) {
          List<dynamic> nowWatch = widget.watch!();
          if (RStore._isWatchValuesUpdates(_lastWatch, nowWatch)) {
            widget.onChange?.call(context);
            _lastWatch = RStore._cloneWatchList(nowWatch);
            // check mounted because onChange can unmount
            if (mounted && widget.builder != null) setState(() {});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _setStoreSubscription?.cancel();
    _changeStoreSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder == null) {
      return widget.child ?? const SizedBox.shrink();
    }
    return widget.builder!.call(context, widget.child);
  }
}
