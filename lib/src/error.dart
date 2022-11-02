/// The error that will be thrown if the WStore cannot be found in the
/// Widget tree.
class WStoreNotFoundError extends Error {
  /// The variable of wstore being retrieved
  final String variable;

  /// The type of the value being retrieved
  final Type valueType;

  /// The type of the Widget requesting the value
  final Type widgetType;

  WStoreNotFoundError(this.valueType, this.widgetType, this.variable);

  @override
  String toString() {
    if (variable.isNotEmpty) {
      return '''Error: Could not find ${variable.toLowerCase()} for this WStore.

$variable sets only in WStoreWidget.
Make sure that WStore is under your WStoreWidget.
To fix, please create WStore in WStoreWidget.

Or WStoreWidget has been unmounted, so the RState no longer has a ${variable.toLowerCase()}
(${variable.toLowerCase()} called after RState.dispose).
''';
    }
    return '''Error: Could not find the correct WStoreWidget<$valueType> above this $widgetType Widget.

Make sure that $widgetType is under your WStoreWidget<$valueType>.

To fix, please add to top of your widget tree:
  class YourWidget extends WStoreWidget<$valueType>(
   $valueType createWStore() => $valueType(),
   Widget build(context, store) => $widgetType(...
''';
  }
}
