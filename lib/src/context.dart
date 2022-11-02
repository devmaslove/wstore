import 'package:flutter/material.dart';

import 'store.dart';

/// Exposes the [store] method.
extension WStoreContext on BuildContext {
  /// Obtains the nearest [WStoreWidget] up its widget tree
  /// and returns its store.
  ///
  /// Same as [WStoreWidget.store]
  T store<T extends WStore>() {
    return WStoreWidget.store<T>(this);
  }
}
