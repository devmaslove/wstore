import 'package:flutter/material.dart';

import 'store.dart';

/// Exposes the [wstore] method.
extension WStoreContext on BuildContext {
  /// Obtains the nearest [WStoreWidget] up its widget tree
  /// and returns its store.
  ///
  /// Same as [WStoreWidget.store]
  T wstore<T extends WStore>() {
    return WStoreWidget.store<T>(this);
  }
}
