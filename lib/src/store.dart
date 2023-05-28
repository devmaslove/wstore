import 'dart:async';

import 'package:flutter/material.dart';

import 'error.dart';
import 'inherited.dart';

class WStore {
  late final StreamController<bool> _controllerWatchers;
  late final Stream<bool> _streamWatchers;
  late final StreamController<List<String>> _controllerNames;
  late final Stream<List<String>> _streamNames;
  final Map<String, dynamic> _convertedValues = {};
  final Map<String, StreamSubscription?> _convertedSubscriptions = {};
  final Map<String, StreamSubscription?> _convertedSubscriptions2 = {};
  final Map<String, dynamic> _computedValues = {};
  final Map<String, dynamic> _computedWatchList = {};
  final Map<String, dynamic> _computedWatchFunc = {};
  final Map<int, Timer> _timers = {};
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, StreamSubscription> _subscriptions = {};
  final Map<int, StreamSubscription> _subscriptions2 = {};
  WStoreWidget? _widget;
  int _prevId = 0;

  /// Get [WStoreWidget] associated with this store.
  @protected
  WStoreWidget get widget {
    if (_widget == null) {
      throw WStoreNotFoundError(WStore, WStoreWidget, "Widget");
    }
    return _widget!;
  }

  /// Creates a reactive store.
  WStore() {
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
  /// int get computedValue => computed<int>(
  ///   getValue: () => storeValue + 1,
  ///   watch: () => [storeValue],
  ///   keyName: 'computedValue',
  /// );
  /// ```
  @protected
  V computed<V>({
    required V Function() getValue,
    required List<dynamic> Function() watch,
    required String keyName,
  }) {
    if (_computedValues.containsKey(keyName)) {
      return _computedValues[keyName];
    }
    V value = getValue();
    _computedValues[keyName] = value;
    _computedWatchList[keyName] = _cloneWatchList(watch());
    _computedWatchFunc[keyName] = watch;
    return value;
  }

  /// Get value from stream and cache it for add to Builders watch lists:
  ///
  /// ```dart
  /// String get computedStreamValue => computedFromStream<String>(
  ///   stream: Stream<String>.value('stream data'),
  ///   initialValue: '',
  ///   keyName: 'computedStreamValue',
  /// );
  /// ```
  ///
  /// computedStreamValue gets '', 'stream data'
  @protected
  V computedFromStream<V>({
    required Stream<V> stream,
    required final V initialData,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    return computedConverter<V, V>(
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
  /// String get computedFutureValue => computedFromFuture<String>(
  ///   future: Future<String>.value('future data'),
  ///   initialValue: '',
  ///   keyName: 'computedFutureValue',
  /// );
  /// ```
  ///
  /// computedFutureValue gets '', 'future data'
  @protected
  V computedFromFuture<V>({
    required Future<V> future,
    required final V initialData,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    return computedConverter<V, V>(
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
  /// String get computedConvertedValue => computedConverter<int, String>(
  ///   stream: Stream.fromIterable([1, 2, 3])
  ///   getValue: (data) => '$data',
  ///   initialValue: '',
  ///   keyName: 'computedConvertedValue',
  /// );
  /// ```
  ///
  /// computedConvertedValue gets '', '1', '2', '3'
  @protected
  V computedConverter<T, V>({
    Stream<T>? stream,
    Future<T>? future,
    required V Function(T) getValue,
    required final V initialValue,
    required final String keyName,
    final List<String> setStoreNames = const [],
    void Function(Object, StackTrace)? onError,
  }) {
    if (_convertedValues.containsKey(keyName)) {
      return _convertedValues[keyName];
    }
    V oldValue = initialValue;
    _convertedValues[keyName] = initialValue;
    assert(!(stream != null && future != null),
        'Only one must be defined at computedConverter - stream or future');
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
  /// int get computedConverted2 => computedConverter2<int, int, int>(
  ///   streamA: Stream<int>.value(1)
  ///   streamB: Stream<int>.fromIterable([0, 1, 2])
  ///   getValue: (a, b) => a + b,
  ///   initialValue: -1,
  ///   keyName: 'computedConverted2',
  /// );
  /// ```
  ///
  /// computedConverted2 gets -1, 1, 2, 3
  @protected
  V computedConverter2<A, B, V>({
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
    if (_convertedValues.containsKey(keyName)) {
      return _convertedValues[keyName];
    }
    V oldValue = initialValue;
    _convertedValues[keyName] = initialValue;
    A? dataA;
    B? dataB;
    assert(
        !(streamA != null && futureA != null) &&
            !(streamB != null && futureB != null),
        'Only one must be defined at computedConverter2 - stream or future');
    Stream<A>? streamWatchA = streamA ?? futureA?.asStream();
    _convertedSubscriptions[keyName] = streamWatchA?.listen(
      (data) {
        dataA = data;
        if (dataA is A && dataB is B) {
          final V newValue = getValue(dataA as A, dataB as B);
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
        if (dataA is A && dataB is B) {
          final V newValue = getValue(dataA as A, dataB as B);
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
  /// Timers are automatically canceled when WStore.dispose
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
  /// Timers are automatically canceled when WStore.dispose
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
  /// Timers are automatically canceled when WStore.dispose
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
  /// killTimer called when WStore.dispose
  /// or when created a new one with same timerId
  void killTimer({required final int timerId}) {
    _timers.remove(timerId)?.cancel();
  }

  /// Create new stream subscription
  ///
  /// Subscriptions are automatically canceled when WStore.dispose
  /// or when created a new one with same subscriptionId
  int subscribe<V>({
    Stream<V>? stream,
    Future<V>? future,
    final int? subscriptionId,
    void Function(V)? onData,
    void Function(Object, StackTrace)? onError,
    void Function()? onDone,
    bool? cancelOnError,
    final Duration? debounceDuration,
  }) {
    assert(
      subscriptionId == null || subscriptionId >= 0,
      'subscriptionId must be positive integer',
    );
    final int id = subscriptionId ?? _getNextID();
    // cancel old subscription
    cancelSubscription(subscriptionId: id);
    //
    assert(
      !(stream != null && future != null),
      'Only one must be defined at subscribe - stream or future',
    );
    Stream<V>? subscribeStream = stream ?? future?.asStream();
    assert(
      subscribeStream != null,
      'Stream or future must be defined at subscribe',
    );
    if (subscribeStream == null) return id;
    // create new subscription
    _subscriptions[id] = subscribeStream.listen(
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

  /// Create new subscription to two streams, and get data by calling the
  /// [onData] function whenever any of the stream sequences emits an item.
  ///
  /// onData will not be called until all streams have emitted at least one
  /// item.
  ///
  /// Subscriptions are automatically canceled when WStore.dispose
  /// or when created a new one with same subscriptionId
  int subscribe2<A, B>({
    Stream<A>? streamA,
    Future<A>? futureA,
    Stream<B>? streamB,
    Future<B>? futureB,
    required void Function(A, B) onData,
    final int? subscriptionId,
    void Function(Object, StackTrace)? onError,
    void Function()? onDone,
    bool? cancelOnError,
    final Duration? debounceDuration,
  }) {
    assert(
      subscriptionId == null || subscriptionId >= 0,
      'subscriptionId must be positive integer',
    );
    final int id = subscriptionId ?? _getNextID();
    // cancel old subscription
    cancelSubscription(subscriptionId: id);
    //
    assert(
      !(streamA != null && futureA != null) &&
          !(streamB != null && futureB != null),
      'Only one must be defined at subscribe2 - stream or future',
    );
    Stream<A>? subscribeStreamA = streamA ?? futureA?.asStream();
    Stream<B>? subscribeStreamB = streamB ?? futureB?.asStream();
    assert(
      (subscribeStreamA != null && subscribeStreamB != null),
      'StreamA or futureA and StreamB or futureB must be defined at subscribe2',
    );
    if (subscribeStreamA == null || subscribeStreamB == null) return id;
    // create new subscription
    A? dataA;
    B? dataB;
    _subscriptions[id] = subscribeStreamA.listen(
      (data) {
        dataA = data;
        if (dataA is A && dataB is B) {
          if (debounceDuration != null) {
            _debounceTimers.remove(id)?.cancel();
            _debounceTimers[id] = Timer(debounceDuration, () {
              _debounceTimers.remove(id)?.cancel();
              onData(dataA as A, dataB as B);
            });
          } else {
            onData(dataA as A, dataB as B);
          }
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    _subscriptions2[id] = subscribeStreamB.listen(
      (data) {
        dataB = data;
        if (dataA is A && dataB is B) {
          if (debounceDuration != null) {
            _debounceTimers.remove(id)?.cancel();
            _debounceTimers[id] = Timer(debounceDuration, () {
              _debounceTimers.remove(id)?.cancel();
              onData(dataA as A, dataB as B);
            });
          } else {
            onData(dataA as A, dataB as B);
          }
        }
      },
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
  /// cancelSubscription called when WStore.dispose
  /// or when created a new one with same subscriptionId
  void cancelSubscription({required final int subscriptionId}) {
    _subscriptions.remove(subscriptionId)?.cancel();
    _subscriptions2.remove(subscriptionId)?.cancel();
    _debounceTimers.remove(subscriptionId)?.cancel();
  }

  /// Called when [WStoreWidget] is removed from the tree permanently.
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
    _subscriptions2.forEach((_, subscription) {
      subscription.cancel();
    });
    _subscriptions2.clear();
    _debounceTimers.forEach((_, timer) {
      timer.cancel();
    });
    _debounceTimers.clear();
    // clear all computedConverter subscriptions
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
    final computedWatchList = {..._computedWatchList};
    final computedValues = {..._computedValues};
    final computedWatchFunc = {..._computedWatchFunc};
    //
    final List<String> removedKeys = [];
    computedWatchList.forEach((key, value) {
      List<dynamic> oldWatch = value;
      // if watchFunc call composed - it modify _computedWatchList
      // that's why we make a copy
      List<dynamic> newWatch = computedWatchFunc[key]?.call() ?? const [];
      if (_isWatchValuesUpdates(oldWatch, newWatch)) {
        computedValues.remove(key);
        computedWatchFunc.remove(key);
        removedKeys.add(key);
      }
    });
    if (removedKeys.isNotEmpty) {
      for (final key in removedKeys) {
        computedWatchList.remove(key);
      }
      _computedWatchList.clear();
      _computedWatchList.addAll(computedWatchList);
      _computedValues.clear();
      _computedValues.addAll(computedValues);
      _computedWatchFunc.clear();
      _computedWatchFunc.addAll(computedWatchFunc);
      // run again to check if nested composed has changed
      _checkChangeComposed();
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

abstract class WStoreWidget<T extends WStore> extends StatefulWidget {
  const WStoreWidget({Key? key}) : super(key: key);

  @protected
  Widget build(BuildContext context, T store);

  /// Creates the [WStore] for this widget
  @protected
  T createWStore();

  /// Will be called once after the widget has been mounted to WStore.
  @protected
  void initWStore(T store) {}

  @override
  State<WStoreWidget<T>> createState() => _WStoreWidgetState<T>();

  /// Obtains the nearest [WStoreWidget] up its widget tree
  /// and returns its store.
  static T store<T extends WStore>(BuildContext context) {
    var widget = context
        .getElementForInheritedWidgetOfExactType<InheritedWStore<T>>()
        ?.widget;
    if (widget == null) {
      throw WStoreNotFoundError(T, context.widget.runtimeType, '');
    } else {
      return (widget as InheritedWStore<T>).store;
    }
  }
}

class _WStoreWidgetState<T extends WStore> extends State<WStoreWidget<T>> {
  late T store;
  bool initStore = false;

  @override
  void initState() {
    store = widget.createWStore();
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
      widget.initWStore(store);
    }
    return InheritedWStore<T>(
      store: store,
      child: widget.build(context, store),
    );
  }
}

class WStoreConsumer extends StatefulWidget {
  final WStore store;
  final List<dynamic> Function()? watch;
  final String? name;
  final Widget Function(BuildContext context, Widget? child)? builder;
  final void Function(BuildContext context)? onChange;

  /// The child widget to pass to the builder, should not be rebuilt
  final Widget? child;

  const WStoreConsumer({
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
  State<WStoreConsumer> createState() => _WStoreConsumerState();
}

class _WStoreConsumerState extends State<WStoreConsumer> {
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
      _lastWatch = WStore._cloneWatchList(widget.watch!());
      _setStoreSubscription = widget.store._streamWatchers.listen((_) {
        if (_lastWatch.isNotEmpty && mounted) {
          List<dynamic> nowWatch = widget.watch!();
          if (WStore._isWatchValuesUpdates(_lastWatch, nowWatch)) {
            widget.onChange?.call(context);
            _lastWatch = WStore._cloneWatchList(nowWatch);
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
