import 'package:flutter/material.dart';

import 'store.dart';

class InheritedRStore<T extends RStore> extends InheritedWidget {
  final T store;
  final BoxConstraints constraints;

  const InheritedRStore({
    Key? key,
    required Widget child,
    required this.store,
    required this.constraints,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedRStore<T> oldWidget) {
    return oldWidget.constraints != constraints;
  }
}
