/// The error that will be thrown if the RStore cannot be found in the
/// Widget tree.
class RStoreNotFoundError extends Error {
  /// The variable of Rstore being retrieved
  final String variable;

  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;

  RStoreNotFoundError(this.valueType, this.widgetType, this.variable);

  @override
  String toString() {
    if (variable.isNotEmpty) {
      return '''Error: Could not find ${variable.toLowerCase()} for this RStore.

$variable sets only in RStoreWidget.
Make sure that RStore is under your RStoreWidget.
To fix, please create RStore in RStoreWidget.

Or RStoreWidget has been unmounted, so the RState no longer has a ${variable.toLowerCase()}
(${variable.toLowerCase()} called after RState.dispose).
''';
    }
    return '''Error: Could not find the correct RStoreWidget<$valueType> above this $widgetType Widget.

Make sure that $widgetType is under your RStoreWidget<$valueType>.

To fix, please add to top of your widget tree:
  class YourWidget extends RStoreWidget<$valueType>(
   $valueType createRStore() => $valueType(),
   Widget build(context, store) => $widgetType(...
''';
  }
}
