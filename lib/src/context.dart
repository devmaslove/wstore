import 'package:flutter/material.dart';

import 'store.dart';

/// Exposes the [store] method.
extension RStoreContext on BuildContext {
  /// Obtains the nearest [RStoreWidget] up its widget tree
  /// and returns its store.
  ///
  /// Same as [RStoreWidget.store]
  T store<T extends RStore>() {
    return RStoreWidget.store<T>(this);
  }
}
