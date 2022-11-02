import 'package:flutter/material.dart';

import 'store.dart';

class InheritedWStore<T extends WStore> extends InheritedWidget {
  final T store;

  const InheritedWStore({
    Key? key,
    required Widget child,
    required this.store,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWStore<T> oldWidget) {
    return false;
  }
}
