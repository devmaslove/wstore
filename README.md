# RStore

RStore - это библиотека для state manage во Flutter.

## Idea

Основная идея в том чтобы разделить представление от логики
по типу того как это делается во Vue.js: шаблон занимается отображением,
а в слое data находятся данные (которые вставляются в шаблон)
и методы/функции (которые дергает шаблон по событиям).

Хочется также просто - объявляем переменную, пихаем её в нужный
виджет, при изменении переменной виджет сам меняется.

Ну и перестраиваться должны только те виджеты в которых поменялись
связанные данные.

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

- Можно использовать только StatelessWidget для полноценного приложения
- Можно использовать простые типы данных без всяких обёрток (не нужно на каждую переменную создавать обертку)
- Используем RStoreBuilder - как принято стандартно во Flutter без скрытой магии строим виджеты через билдеры
- Встроенный RStoreProvider чтобы передать RStore вниз по дереву
- Маленький и понятный интерфейс - setStore, Builder и Provider

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
        builder: (context) => Text(
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

## Additional information

Для того чтобы подписаться только на одну переменную можно использовать
шаблон `RStoreValueBuilder`:

```dart
RStoreValueBuilder<int>(
  store: store,
  watch: () => store.counter,
  builder: (context, counter) {
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
      store: _MyAppStore(),
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
  builder: (context, counter) {
    return Text(
      '$counter',
      style: Theme.of(context).textTheme.headline4,
    );
  },
)

RStoreContextBuilder<_MyAppStore>(
  watch: (store) => [store.counter],
  builder: (context, store) => Text(
    '${store.counter}',
    style: Theme.of(context).textTheme.headline4,
  ),
)
```
