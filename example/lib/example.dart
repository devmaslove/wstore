import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class MyWidgetStore extends WStore {
  // ТУТ ДАННЫЕ И ЛОГИКА ДЛЯ ВИДЖЕТОВ

  @override
  MyWidget get widget => super.widget as MyWidget;
}

class MyWidget extends WStoreWidget<MyWidgetStore> {
  const MyWidget({
    Key? key,
  }) : super(key: key);

  @override
  MyWidgetStore createWStore() => MyWidgetStore();

  @override
  Widget build(BuildContext context, MyWidgetStore store) {
    return Container(
        // ТУТ ДЕРЕВО ВИДЖЕТОВ
        );
  }
}
