# RStore

RStore - это библиотека для state manage во Flutter.
Добавляем реактивность в наши виджеты.

## Idea

Основная идея в том чтобы разделить представление от логики
по типу того как это делается во Vue.js: шаблон занимается отображением,
а в data находятся данные (которые вставляются в шаблон)
и методы/функции (которые дергает шаблон по событиям).

При таком подходе из виджетов выносится вообще вся логика, их задача
просто отобразить готовые данные или дернуть нужную функцию.

Хочется также просто как во Vue.js - объявляем переменную, пихаем её
в нужный виджет, при изменении переменной виджет сам меняется.
Перестраиваться должны только те виджеты в которых поменялись
связанные данные.

И без магии, чтобы работало по стандартам Flutter:
вот данные - вот билдер на основе этих данных.

В поисках решения я натолкнулся на [consumer](https://pub.dev/packages/consumer) -
то что надо! Только допилить напильником :)

## Concept

Создаем обычный класс с данными - много разных переменных
(наследник `RStore`).

Добавляем отображение данных в дерево виджетов с помощью билдера
(например `RStoreBuilder`).

В билдере прописываем за изменениями каких переменных он будет следить
(список `watch`).

При изменении данных вызываем у класса `setStore` для уведомления билдеров
что данные изменились.

## Features

- Виджеты сами перестраиваются в зависимости от данных в `RStore`, не нужно управлять подписками
- Можно использовать простые типы данных без всяких обёрток (не нужно на каждую переменную создавать обертку)
- Используем RStoreBuilder - как принято стандартно во Flutter без скрытой магии строим виджеты через билдеры
- Встроенный RStoreProvider чтобы создать передать RStore вниз по дереву
- Маленький, простой и понятный интерфейс - setStore, Builder и Provider

## Install

Change `pubspec.yaml` (and run an implicit pub get):

```yaml
dependencies:
  reactive_store:
    git:
      url: https://github.com/dmitrymaslovhome/reactive_store
```

## Usage

Создаем класс с данными:

```dart
class _MyAppStore extends RStore {
  int counter = 0;

  void incrementCounter() {
    setStore(() {
      counter++;
    });
  }
}

final store = _MyAppStore();
```

Билдим данные в дерево виджетов:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: RStoreBuilder(
        store: store,
        watch: () => [store.counter],
        builder: (context, _) => Text(
          '${store.counter}',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: store.incrementCounter,
      child: const Icon(Icons.add),
    ),
  );
}
```

Также можно сделать билдер который обновляется вручную по строковому `tag`.
Для этого используем `RStoreTagBuilder`, а в `setStore` указываем `tags`:
```dart
RStoreTagBuilder(
  store: store,
  tag: 'name of builder',
  builder: (context, _) {
    return Text(
      '${store.counter}',
      style: Theme.of(context).textTheme.headline4,
    );
  },
),

...

// update builder by tag
store.setStore(() => store.counter++, tags: ['name of builder']);
```

TagBuilder использовать только если требуется быстро написать
логику для отображения сложных структур данных. Потом нужно отрефакторить и
переписать всё на watch листы.

## Additional information

Для того чтобы подписаться только на одну переменную можно использовать
шаблон `RStoreValueBuilder`:

```dart
RStoreValueBuilder<int>(
  store: store,
  watch: () => store.counter,
  builder: (context, counter, _) {
    return Text(
      '$counter',
      style: Theme.of(context).textTheme.headline4,
    );
  },
),
```

Для пробрасывания хранилища по дереву виджетов можно использовать
`RStoreProvider`:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    home: RStoreProvider<_MyAppStore>(
      create: () => _MyAppStore(),
      child: const _MyAppContent(),
    ),
  );
}


@override
Widget build(BuildContext context) {
  final store = RStoreProvider.of<_MyAppStore>(context);
  ...
```

`RStoreProvider` позволяет использовать контекстные билдеры которые
сами находят хранилище:

```dart
RStoreContextValueBuilder<_MyAppStore, int>(
  watch: (store) => store.counter,
  builder: (context, counter, _) {
    return Text(
      '$counter',
      style: Theme.of(context).textTheme.headline4,
    );
  },
)

RStoreContextBuilder<_MyAppStore>(
  watch: (store) => [store.counter],
  builder: (context, store, _) => Text(
    '${store.counter}',
    style: Theme.of(context).textTheme.headline4,
  ),
)

RStoreContextTagBuilder<_MyAppStore>(
  tag: 'name of builder',
  builder: (context, store, _) => Text(
    '${store.counter}',
    style: Theme.of(context).textTheme.headline4,
  ),
)
```

В билдеры можно передать виджет в `child` который не должен ребилдится
при изменении:

```dart
RStoreValueBuilder<int>(
  store: store,
  watch: () => store.counter,
  child: Text('Button has been pressed:'), // not be rebuilt
  builder: (context, counter, child) {
    return Column(
      children: [
        child,
        Text(
          '$counter',
          style: Theme.of(context).textTheme.headline4,
        ),
      ],
    );
  },
),
```

Когда нужно вывести модифицированную информацию из хранилища
добавляем геттер и оборачиваем в метод `compose`, тогда билдеры будут
обновляться только когда пересчитается значение.

Например, делаем геттер `doubleCounter` который возвращает удвоенное значение `counter`.
Для этого оборачиваем всё в метод `compose` в котором говорим, что значение надо
пересчитать при обновлении `counter` и задаём уникальный ключ в кеше `"doubleCounter"`:

```dart
class _MyAppStore extends RStore {
  int counter = 0;

  get doubleCounter => compose<int>(
        getValue: () => counter * 2,
        watch: () => [counter],
        keyName: "doubleCounter",
      );

  void incrementCounter() {
    setStore(() {
      counter++;
    });
  }
}
```

Таким образом билдеры зависимые от `doubleCounter` не будут обновляться в холостую
при каждом обновлении сторы, а пересчитаются только при изменении `counter`. Да,
кода надо писать порядком, но зато всё прозрачно. 

С помощью `compose` можно вычислять, например, сумму массива или мапить элементы.

## RStoreWidget

Для удобства создания виджетов со сторой сделан класс `RStoreWidget`.

Когда `RStore` создается через него, то она дополнительно получает доступ к этому виджету
`RStore.widget`, к его контексту `RStore.context` и к его максимальным размерам `RStore.constraints`.
Также пробрасывается вниз по дереву через `RStoreProvider`.

Просто немного удобства, чтобы сразу в сторе иметь доступ ко входящим параметрам виджета, к
его калбекам, чтобы в зависимости от constraints делать какую-то логику, обращаться к текущему
контексту. Иначе пришлось бы это всё руками пробрасывать.

Чтобы было ещё удобнее с этим работать рекомендую добавить сниппеты кода:

### Android Studio - Life Template

```dart
import 'package:flutter/material.dart';
import 'package:reactive_store/reactive_store.dart';

class $STORE_NAME$ extends RStore {
  static $STORE_NAME$ of(BuildContext context) {
    return RStoreProvider.of<$STORE_NAME$>(context);
  }

  @override
  $WIDGET_NAME$ get widget => super.widget as $WIDGET_NAME$;
}

class $NAME$ extends RStoreWidget<$STORE_NAME$> {
  const $WIDGET_NAME$({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, $STORE_NAME$ store) {
    return Container($END$);
  }

  @override
  $STORE_NAME$ createRStore() => $STORE_NAME$();
}
```

Где:

- `Applicable context` - равно `Applicable in Dart: top-level.`
- `NAME` - начальная точка
- `WIDGET_NAME` - равно `NAME` + skip if defined
- `STORE_NAME` - равно `regularExpression(concat("_", WIDGET_NAME, "Store"), "^__", "_")` + skip if defined
- `END` - конечная точка

## Built upon

Под капотом это использует обычную механику Flatter`а:

- RStore - создает стримы которые пушатся по setStore
- Билдеры - это StatefulWidget`ы которые подписываются на стримы из RStore
- Если watch лист изменился то вызывается setState и происходит ребилд (сравнение элементов в watch происходит по ссылке - по этому в RStore надо перезаписывать объект, чтобы подхватилось изменения)
- RStoreProvider оборачивает RStore в InheritedWidget
