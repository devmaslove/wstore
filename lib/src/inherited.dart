import 'package:flutter/material.dart';

import 'store.dart';

class InheritedRStore<T extends RStore> extends InheritedWidget {
  final T store;

  const InheritedRStore({
    Key? key,
    required Widget child,
    required this.store,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedRStore<T> oldWidget) {
    return false;
  }
}
