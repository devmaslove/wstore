import 'dart:async';

import 'package:flutter/material.dart';

import 'error.dart';
import 'inherited.dart';

class RStore {
  late final StreamController<bool> _controllerWatchers;
  late final Stream<bool> _streamWatchers;
  late final StreamController<List<String>> _controllerNames;
  late final Stream<List<String>> _streamNames;
  final Map<String, dynamic> _convertedValues = {};
  final Map<String, StreamSubscription?> _convertedSubscriptions = {};
  final Map<String, StreamSubscription?> _convertedSubscriptions2 = {};
  final Map<String, dynamic> _composedValues = {};
  final Map<String, dynamic> _composedWatchList = {};
  final Map<String, dynamic> _composedWatchFunc = {};
  final Map<int, Timer> _timers = {};
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, StreamSubscription> _subscriptions = {};
  RStoreWidget? _widget;
  int _prevId = 0;

  /// Get [RStoreWidget] associated with this store.
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
    _controllerNames = StreamController<List<String>>.broadcast();
    _streamNames = _controllerNames.stream;
  }

  /// Notifying that the store has been updated.
  void setStore(
    VoidCallback fn, [
    final List<String> names = const [],
  ]) {
    final Object? result = fn() as dynamic;
    assert(
      () {
        if (result is Future) return false;
        return true;
      }(),
      'setStore() callback argument returned a Future. '
      'Maybe it is marked as "async"? Instead of performing asynchronous '
      'work inside a call to setStore(), first execute the work '
      '(without updating the store), and then synchronously '
      'update the store inside a call to setStore().',
    );
    // Notifying builders with watchers that the store has been updated
    _checkChangeComposed();
    _controllerWatchers.add(true);
    // Notifying builders with names that the store has been updated and need
    // rebuild
    if (names.isNotEmpty) _controllerNames.add([...names]);
  }

  /// Cache values for add to Builders watch lists:
  ///
  /// ```dart
  /// int storeValue = 1;
  ///
  /// int get composeValue => compose<int>(
  ///   getValue: () => storeValue + 1,
  ///   watch: () => [storeValue],
  ///   keyName: 'composeValue',
  /// );
  /// ```
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

  /// Get value from stream and cache it for add to Builders watch lists:
  ///
  /// ```dart
  /// String get composeStreamValue => composeStream<String>(
  ///   stream: Stream<String>.value('stream data')
  ///   initialValue: '',
  ///   keyName: 'composeStreamValue',
  /// );
  /// ```
  ///
  /// composeStreamValue gets '', 'stream data'
  @protected
  V composeStream<V>({
    required Stream<V> stream,
    required final V initialData,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    return composeConverter<V, V>(
      stream: stream,
      getValue: (value) => value,
      initialValue: initialData,
      keyName: keyName,
      setStoreNames: setStoreNames,
      onError: onError,
    );
  }

  /// Get value from future and cache it for add to Builders watch lists:
  ///
  /// ```dart
  /// String get composeFutureValue => composeFuture<String>(
  ///   future: Future<String>.value('future data')
  ///   initialValue: '',
  ///   keyName: 'composeFutureValue',
  /// );
  /// ```
  ///
  /// composeFutureValue gets '', 'future data'
  @protected
  V composeFuture<V>({
    required Future<V> future,
    required final V initialData,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    return composeConverter<V, V>(
      stream: future.asStream(),
      getValue: (value) => value,
      initialValue: initialData,
      keyName: keyName,
      setStoreNames: setStoreNames,
      onError: onError,
    );
  }

  /// Convert data from stream and cache result value
  /// for add to Builders watch lists:
  ///
  /// ```dart
  /// String get composeConvertedValue => composeConverter<int, String>(
  ///   stream: Stream.fromIterable([1, 2, 3])
  ///   getValue: (data) => '$data',
  ///   initialValue: '',
  ///   keyName: 'composeConvertedValue',
  /// );
  /// ```
  ///
  /// composeConvertedValue gets '', '1', '2', '3'
  @protected
  V composeConverter<T, V>({
    Stream<T>? stream,
    Future<T>? future,
    required V Function(T) getValue,
    required final V initialValue,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    V? value = _convertedValues[keyName];
    if (value is V) return value;
    V oldValue = initialValue;
    _convertedValues[keyName] = initialValue;
    assert(!(stream != null && future != null),
        'Only one must be defined at composeConverter - stream or future');
    Stream<T>? streamWatch = stream ?? future?.asStream();
    _convertedSubscriptions[keyName] = streamWatch?.listen(
      (data) {
        final V newValue = getValue(data);
        if (!_isValuesEquals(newValue, oldValue)) {
          oldValue = newValue;
          setStore(() => _convertedValues[keyName] = newValue, setStoreNames);
        }
      },
      onError: onError,
    );
    return initialValue;
  }

  /// Convert data from two streams and cache result value
  /// for add to Builders watch lists:
  ///
  /// ```dart
  /// int get composeConverted2 => composeConverter2<int, int, int>(
  ///   streamA: Stream<int>.value(1)
  ///   streamB: Stream<int>.fromIterable([0, 1, 2])
  ///   getValue: (a, b) => a + b,
  ///   initialValue: -1,
  ///   keyName: 'composeConverted2',
  /// );
  /// ```
  ///
  /// composeConverted2 gets -1, 1, 2, 3
  @protected
  V composeConverter2<A, B, V>({
    Stream<A>? streamA,
    Future<A>? futureA,
    Stream<B>? streamB,
    Future<B>? futureB,
    required V Function(A, B) getValue,
    required final V initialValue,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    V? value = _convertedValues[keyName];
    if (value is V) return value;
    V oldValue = initialValue;
    _convertedValues[keyName] = initialValue;
    A? dataA;
    B? dataB;
    assert(
        !(streamA != null && futureA != null) &&
            !(streamB != null && futureB != null),
        'Only one must be defined at composeConverter2 - stream or future');
    Stream<A>? streamWatchA = streamA ?? futureA?.asStream();
    _convertedSubscriptions[keyName] = streamWatchA?.listen(
      (data) {
        dataA = data;
        if (dataA != null && dataB != null) {
          final V newValue = getValue(dataA!, dataB!);
          if (!_isValuesEquals(newValue, oldValue)) {
            oldValue = newValue;
            setStore(() => _convertedValues[keyName] = newValue, setStoreNames);
          }
        }
      },
      onError: onError,
    );
    Stream<B>? streamWatchB = streamB ?? futureB?.asStream();
    _convertedSubscriptions2[keyName] = streamWatchB?.listen(
      (data) {
        dataB = data;
        if (dataA != null && dataB != null) {
          final V newValue = getValue(dataA!, dataB!);
          if (!_isValuesEquals(newValue, oldValue)) {
            oldValue = newValue;
            setStore(() => _convertedValues[keyName] = newValue, setStoreNames);
          }
        }
      },
      onError: onError,
    );
    return initialValue;
  }

  /// Create new timer
  ///
  /// Timers are automatically canceled when RStore.dispose
  /// or when created a new one with same timerId
  /// (сan be used to set debounce time e.g.)
  int setTimer({
    required final VoidCallback onTimer,
    required final Duration duration,
    final int? timerId,
    final bool periodic = false,
  }) {
    assert(timerId == null || timerId >= 0, 'timerId must be positive integer');
    final int id = timerId ?? _getNextID();
    // kill old timer
    killTimer(timerId: id);
    // create new timer
    if (periodic) {
      _timers[id] = Timer.periodic(duration, (_) => onTimer());
    } else {
      _timers[id] = Timer(duration, () {
        killTimer(timerId: id);
        onTimer();
      });
    }
    return id;
  }

  /// Create new non periodic timer
  ///
  /// Timers are automatically canceled when RStore.dispose
  /// or when created a new one with same timerId
  /// (сan be used to set debounce time e.g.)
  int setTimeout(VoidCallback onTimer, int milliseconds, [int? timerId]) {
    assert(timerId == null || timerId >= 0, 'timerId must be positive integer');
    return setTimer(
      onTimer: onTimer,
      duration: Duration(milliseconds: milliseconds),
      timerId: timerId,
      periodic: false,
    );
  }

  /// Create new periodic timer
  ///
  /// Timers are automatically canceled when RStore.dispose
  /// or when created a new one with same timerId
  /// (сan be used to set debounce time e.g.)
  int setInterval(VoidCallback onTimer, int milliseconds, [int? timerId]) {
    assert(timerId == null || timerId >= 0, 'timerId must be positive integer');
    return setTimer(
      onTimer: onTimer,
      duration: Duration(milliseconds: milliseconds),
      timerId: timerId,
      periodic: true,
    );
  }

  /// Cancel timer by timerID
  ///
  /// killTimer called when RStore.dispose
  /// or when created a new one with same timerId
  void killTimer({required final int timerId}) {
    _timers.remove(timerId)?.cancel();
  }

  /// Create new stream subscription
  ///
  /// Subscriptions are automatically canceled when RStore.dispose
  /// or when created a new one with same subscriptionId
  int subscribe<V>({
    required final Stream<V> stream,
    final int? subscriptionId,
    void Function(V)? onData,
    void Function(Object, StackTrace)? onError,
    void Function()? onDone,
    bool? cancelOnError,
    final Duration? debounceDuration,
  }) {
    assert(subscriptionId == null || subscriptionId >= 0,
        'subscriptionId must be positive integer');
    final int id = subscriptionId ?? _getNextID();
    // cancel old subscription
    cancelSubscription(subscriptionId: id);
    // create new subscription
    _subscriptions[id] = stream.listen(
      onData != null
          ? (value) {
              if (debounceDuration != null) {
                _debounceTimers.remove(id)?.cancel();
                _debounceTimers[id] = Timer(debounceDuration, () {
                  _debounceTimers.remove(id)?.cancel();
                  onData(value);
                });
              } else {
                onData(value);
              }
            }
          : null,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    return id;
  }

  /// Subscribe to stream
  ///
  /// Create new stream subscription.
  /// You can set msDebounce (number of millisecond)
  /// to set debounce time.
  int listenStream<V>(
    final Stream<V> stream, {
    final int? id,
    final int msDebounce = 0,
    required void Function(V) onData,
    void Function(Object, StackTrace)? onError,
  }) {
    assert(id == null || id >= 0, 'id must be positive integer');
    return subscribe<V>(
      stream: stream,
      onData: onData,
      onError: onError,
      subscriptionId: id,
      debounceDuration:
          msDebounce > 0 ? Duration(milliseconds: msDebounce) : null,
    );
  }

  /// Subscribe to future
  ///
  /// Create new stream subscription
  int listenFuture<V>(
    final Future<V> future, {
    final int? id,
    required void Function(V) onData,
    void Function(Object, StackTrace)? onError,
  }) {
    assert(id == null || id >= 0, 'id must be positive integer');
    return subscribe<V>(
      stream: future.asStream(),
      onData: onData,
      onError: onError,
      subscriptionId: id,
    );
  }

  /// Cancel subscription by subscriptionID
  ///
  /// cancelSubscription called when RStore.dispose
  /// or when created a new one with same subscriptionId
  void cancelSubscription({required final int subscriptionId}) {
    _subscriptions.remove(subscriptionId)?.cancel();
    _debounceTimers.remove(subscriptionId)?.cancel();
  }

  /// Called when [RStoreWidget] is removed from the tree permanently.
  @mustCallSuper
  void dispose() {
    // clear widget
    _widget = null;
    // clear all timers
    _timers.forEach((_, timer) {
      timer.cancel();
    });
    _timers.clear();
    // clear all subscriptions with debounceTimers
    _subscriptions.forEach((_, subscription) {
      subscription.cancel();
    });
    _subscriptions.clear();
    _debounceTimers.forEach((_, timer) {
      timer.cancel();
    });
    _debounceTimers.clear();
    // clear all composeConverter subscriptions
    _convertedSubscriptions.forEach((_, subscription) {
      subscription?.cancel();
    });
    _convertedSubscriptions.clear();
    _convertedSubscriptions2.forEach((_, subscription) {
      subscription?.cancel();
    });
    _convertedSubscriptions2.clear();
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

  int _getNextID() {
    _prevId--;
    return _prevId;
  }

  static bool _isWatchValuesUpdates(
    final List<dynamic> oldWatch,
    final List<dynamic> newWatch,
  ) {
    if (oldWatch.length == newWatch.length) {
      for (var i = 0; i < oldWatch.length; i++) {
        if (!_isValuesEquals(oldWatch[i], newWatch[i])) return true;
      }
    }
    return false;
  }

  static List<dynamic> _cloneWatchList(final List<dynamic> watchList) {
    // TODO: need deep copy - lists, maps, sets
    // List newList = json.decode(json.encode(oldList));
    return [...watchList];
  }

  static bool _isValuesEquals(dynamic oldValue, dynamic newValue) {
    // TODO: need deep compare - lists, maps, sets (listEquals)
    // or maybe add param deep equals?
    return oldValue == newValue;
  }
}

abstract class RStoreWidget<T extends RStore> extends StatefulWidget {
  const RStoreWidget({Key? key}) : super(key: key);

  @protected
  Widget build(BuildContext context, T store);

  /// Creates the [RStore] for this widget
  @protected
  T createRStore();

  /// Will be called once after the widget has been mounted to RStore.
  @protected
  void initRStore(T store) {}

  @override
  State<RStoreWidget<T>> createState() => _RStoreWidgetState<T>();

  /// Obtains the nearest [RStoreWidget] up its widget tree
  /// and returns its store.
  static T store<T extends RStore>(BuildContext context) {
    var widget = context
        .getElementForInheritedWidgetOfExactType<InheritedRStore<T>>()
        ?.widget;
    if (widget == null) {
      throw RStoreNotFoundError(T, context.widget.runtimeType, '');
    } else {
      return (widget as InheritedRStore<T>).store;
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
    store._widget = widget;
    if (!initStore) {
      initStore = true;
      widget.initRStore(store);
    }
    return InheritedRStore<T>(
      store: store,
      child: widget.build(context, store),
    );
  }
}

class RStoreConsumer extends StatefulWidget {
  final RStore store;
  final List<dynamic> Function()? watch;
  final String? name;
  final Widget Function(BuildContext context, Widget? child)? builder;
  final void Function(BuildContext context)? onChange;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const RStoreConsumer({
    required this.store,
    this.builder,
    this.onChange,
    this.watch,
    this.name,
    this.child,
    Key? key,
  })  : assert(
          name == null || name.length > 0,
          'name must not be empty string',
        ),
        super(key: key);

  @override
  _RStoreConsumerState createState() => _RStoreConsumerState();
}

class _RStoreConsumerState extends State<RStoreConsumer> {
  StreamSubscription<List<String>>? _changeStoreSubscription;
  StreamSubscription<bool>? _setStoreSubscription;
  List<dynamic> _lastWatch = [];

  @override
  void initState() {
    super.initState();

    if (widget.name != null) {
      _changeStoreSubscription = widget.store._streamNames.listen((tags) {
        if (mounted) {
          if (tags.contains(widget.name)) {
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
