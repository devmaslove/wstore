# RStore

RStore - это библиотека для state manage во Flutter.
Добавляем реактивность в наши виджеты.

## Идея

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
переписать всё на watch листы. Разделяем ответственность - стора не должна
знать кто за ней следит.

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

При использовании `RStoreProvider` из контекста можно получить доступ к
максимальным размерам `RStoreProvider.widgetConstraintsOf`
(из размеров также получается `RStoreProvider.widgetOrientationOf`)

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
  builder: (_, counter, child) {
    return Column(
      children: [
        child,
        Text('$counter'),
      ],
    );
  },
),
```

В билдере межно задать функцию `onChange` которая вызывается при изменении
watch листа перед `build` (не вызывается при инициализации):

```dart
RStoreValueBuilder<int>(
  store: store,
  watch: () => store.counter,
  onChange: (context, counter) {
    // делаем тут что-то полезное
    // например, Navigator.pop(context)...
  },
  builder: (__, counter, _) {
    return Text('$counter');
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
`RStore.widget` и также пробрасывается вниз по дереву через `RStoreProvider`.

Просто немного удобства, чтобы сразу в сторе иметь доступ ко входящим параметрам виджета, к
его калбекам. Иначе пришлось бы это всё руками пробрасывать.

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
  $STORE_NAME$ createRStore() => $STORE_NAME$();

  @override
  Widget build(BuildContext context, $STORE_NAME$ store) {
    return Container($END$);
  }
}
```

Где:

- Абреввиатура `rsw` - New RStore widget
- `Applicable context` - равно `Applicable in Dart: top-level.`
- `NAME` - начальная точка
- `WIDGET_NAME` - равно `NAME` + skip if defined
- `STORE_NAME` - равно `regularExpression(concat("_", WIDGET_NAME, "Store"), "^__", "_")` + skip if defined
- `END` - конечная точка

### VS Code - Code snippet

Добавьте сниппет для языка Dart: `.../snippets/dart.json`

User Snippets under File > Preferences (Code > Preferences on macOS),
and then select the Dart language.

```json
{
  "New RStore widget": {
    "prefix": "rsw",
    "body": [
      "import 'package:flutter/material.dart';",
      "import 'package:reactive_store/reactive_store.dart';",
      "",
      "class _$1Store extends RStore {",
      "\tstatic _$1Store of(BuildContext context) {",
      "\t\treturn RStoreProvider.of<_$1Store>(context);",
      "\t}",
      "",
      "\t@override",
      "\t$1 get widget => super.widget as $1;",
      "}",
      "",
      "class ${1:MyWidget} extends RStoreWidget<_$1Store> {",
      "\tconst $1({",
      "\t\tKey? key,",
      "\t}) : super(key: key);",
      "",
      "\t@override",
      "\t_$1Store createRStore() => _$1Store();",
      "",
      "\t@override",
      "\tWidget build(BuildContext context, _$1Store store) {",
      "\t\treturn Container($0);",
      "\t}",
      "}",
      "",
    ]
  }
}
```

## Good practices

**Один "сложный" widget = один стор!** Если потребовалось подключать много сторов -
значит вам нужно вынести часть подвиджетов в отдельный "сложный" widget.
"Сложный" виджет наследуем от RStoreWidget.

**В сторе не делаем функции на получение информации!** Информацию из хранилища получаем
только напрямую из переменных или геттеров. Если нужно как-то обработать данные
перед выводом - делаем геттер и оборачиваем в `compose`.

**Публичные методы сторы только на мутацию данных!** И методы эти не должны что-то
возвращать. Остальную логику скрывать в приватных функциях.

**Тэги и id таймеров/подписок задавать константами в сторе!** Лучше задать всё в одном
месте и использовать от туда, чем копировать одинаковый текст или магические числа по коду.

**Пересоздавайте объекты/мапы/листы в сторе вместо их мутации!** Watch билдеры сравнивают
сложные объекты по ссылке если у них не переопределен оператор равенства. Они просто не
узнают что что-то внутри объекта изменилось. Для совсем сложной логики и данных можно использовать
Tag билдеры, но лучше от этой практики воздерживаться.

## Built upon

Под капотом это использует обычную механику Flatter`а:

- RStore - создает стримы которые пушатся по setStore
- Билдеры - это StatefulWidget`ы которые подписываются на стримы из RStore
- Если watch лист изменился то вызывается setState и происходит ребилд (сравнение элементов в watch происходит по ссылке - по этому в RStore надо перезаписывать объект, чтобы подхватилось изменения)
- RStoreProvider оборачивает RStore в InheritedWidget
