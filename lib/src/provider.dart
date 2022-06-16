import 'package:flutter/material.dart';

import 'error.dart';
import 'inherited.dart';
import 'store.dart';

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
      return InheritedRStore<T>(
        store: store,
        constraints: constraints,
        child: widget.child,
      );
    });
  }
}
