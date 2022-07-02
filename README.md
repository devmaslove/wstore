# RStore

RStore - это библиотека для state manage во Flutter.
Добавляем реактивность в наши виджеты.

## Ключевые особенности

1. Расширяет возможности стандартного `State`:
- Перестраиваются только те виджеты, данные которых изменились
- Стейт прокидывается через контекст - есть доступ к стейту у любого дочернего виджета

2. Также просто работать как с обычным `State`:
- Не нужно управлять подписками
- Можно использовать простые типы данных без всяких обёрток
- Не нужно на каждую переменную создавать отдельную обёртку/отдельный стейт
- Обновления состояния по `setStore`, аналогично как `setState`

3. Работает стандартно, как принято во Flutter, без всякой скрытой магии:
- Зависимые от `RStore` виджеты строятся через `RStoreBuilder`
- `RStoreWidget` - позволяет создавать виджеты со встроенной `RStore` (аналогично как `StatefullWidget`)
- Механика очень схожа с `ValueListenableBuilder` и `ValueNotifier`

4. Легко прокидывать калбеки и входящие параметры головного виджета по дереву дочерних виджетов
- Через `RStore.widget` везде есть доступ к головному виджету

5. Встроенная упрощенная работа с таймерами:
- создание и отмена таймеров по id
- авто отмена таймеров по dispose

## Концепция

Основная идея в том чтобы разделить представление от логики
по типу того как это делается во Vue.js: шаблон занимается отображением,
а в data находятся данные (которые вставляются в шаблон)
и методы/функции (которые дергает шаблон по событиям).

При таком подходе из виджетов выносится вообще вся логика, их задача
просто отобразить готовые данные или дернуть нужную функцию.

Второй момент, то что снаружи это остается всё темже виджетом с
параметрами/калбеками. А как устроена логика - это закрытая внутренняя
кухня виджета.

При этом, хочется сохранить простоту - объявляем переменную, пихаем её
в нужный виджет, при изменении переменной виджет сам меняется.
Перестраиваться должны только те виджеты в которых поменялись
связанные данные. И чтобы без магии, чтобы работало по стандартам Flutter:
вот данные - вот билдер на основе этих данных.

В поисках решения натолкнулся на [consumer](https://pub.dev/packages/consumer) -
то что надо! Только допилить напильником :)

RStore относится к слою представление, по логике представляет собой презентатор
для виджетов. Его задача приобразовать данные от приложения, чтобы их можно было
просто поместить на экран. Это его предназначение, на большее он не претендует.
Он не создан для общей логики для всего приложения или нескольких экранов. Только
для внутреннего состояния конкретных виджетов.

## Установка

В `pubspec.yaml` добавить (сохранить и запустить pub get):

```yaml
dependencies:
  reactive_store:
    git:
      url: https://github.com/devmaslove/reactive_store
```

## Использование

Создаем класс с данными - много разных переменных
(наследник `RStore`).

Добавляем отображение данных в дерево виджетов с помощью билдера
(например `RStoreBuilder`).

В билдере прописываем за изменениями каких переменных он будет следить
(список `watch`).

При изменении данных вызываем у класса `setStore` для уведомления билдеров
что данные изменились.

Создаем класс с данными:

```dart
class MyAppStore extends RStore {
  int counter = 0;

  void incrementCounter() {
    setStore(() {
      counter++;
    });
  }
}

final store = MyAppStore();
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

## RStoreWidget

Для удобства создания виджетов со сторой сделан класс `RStoreWidget`.

При использовании `RStoreWidget` из контекста можно получить доступ к его максимальным
размерам `RStoreWidget.constraints` (из размеров также получается `RStoreWidget.orientation`)

Когда `RStore` создается через него, то она дополнительно получает доступ к этому виджету
`RStore.widget` и также пробрасывается вниз по дереву (доступна через `context`).

Просто немного удобства, чтобы сразу в сторе иметь доступ ко входящим параметрам виджета, к
его калбекам. Иначе пришлось бы это всё руками пробрасывать.

## RStoreWatchBuilder и RStoreValueBuilder

Для того чтобы подписаться на изменения переменных в сторе нужно использовать
список `watch` - список тех переменных за изменениями которых мы следим и при изменении
которых нужно перестроить виджет. Задаем его в `RStoreWatchBuilder`:

```dart
RStoreWatchBuilder(
  store: store,
  watch: () => [store.counter],
  builder: (context, _) {
    return Text(
      '${store.counter}',
      style: Theme.of(context).textTheme.headline4,
    );
  },
),
```

Для того чтобы подписаться только на одну переменную можно использовать
шаблон `RStoreValueBuilder`, тут `watch` возвращает уже не список, а только одно значние,
и это значение также будет передаваться в `builder`:

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

В билдере можно задать функцию `onChange` которая вызывается при изменении
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

Если нам требудется только следить за изменениями без ребилда, то передаем только `child` и не
переопределяем `builder`:

```dart
RStoreValueBuilder<int>(
  store: store,
  watch: () => store.counter,
  onChange: (context, counter) {
    // делаем тут что-то полезное
    // например, Navigator.pop(context)...
  },
  child: Text('Not be rebuilt'),
),
```

## RStoreNamedBuilder - именованные билдеры

Также можно сделать билдер который обновляется вручную по `name`.
Для этого используем `RStoreNamedBuilder`, а в `setStore` указываем `buildersNames`:

```dart
RStoreNamedBuilder(
  store: store,
  name: 'name of builder',
  builder: (context, _) {
    return Text(
      '${store.counter}',
      style: Theme.of(context).textTheme.headline4,
    );
  },
),

...

// update builder by name
store.setStore(() => store.counter++, ['name of builder']);
```

Именованные билдеры не являются "чистой архитектурой", потому что создают зависимости в
обратную сторону, от сторы к билдерам. В идеальном мире нужно разделять отвественность -
стора ничего не должна знать о том где и как её используют и используют ли вообще.

Если вы не являетесь фанатичными приверженцами этих правил и/или живете в не идеальном мире,
в котором требуется быстро написать логику для отображения сложных структур данных, то для
упрощения работы можно использовать именованные билдеры. Но вы должны осознавать основной минус -
код становится связанным и запутанным.

Имена билдеров задавайте константами в сторе. Лучше задать всё в одном
месте и использовать от туда, чем копировать одинаковый "магический" текст по коду.

## RStoreContextBuilder, RStoreContextValueBuilder и RStoreContextNamedBuilder

`RStoreWidget` позволяет использовать билдеры, которые сами находят хранилище в `context`. Можно добавлять
билдеры как обычно, не доставая предварительно стору из контекста. Стора будет передана дополнительным
параметром в `watch`, `builder` и в `onChange`:

```dart
RStoreContextBuilder<MyAppStore>(
  watch: (store) => [store.counter],
  builder: (context, store, _) => Text(
    '${store.counter}',
    style: Theme.of(context).textTheme.headline4,
  ),
)

RStoreContextValueBuilder<MyAppStore, int>(
  watch: (store) => store.counter,
  builder: (context, counter, _) {
    return Text(
      '$counter',
      style: Theme.of(context).textTheme.headline4,
    );
  },
)

RStoreContextNamedBuilder<MyAppStore>(
  name: 'name of builder',
  builder: (context, store, _) => Text(
    '${store.counter}',
    style: Theme.of(context).textTheme.headline4,
  ),
)
```

## Дополнительные возможности RStore

### compose - самообновляемые зависимые данные

Когда нужно вывести модифицированную информацию из хранилища
добавляем геттер и оборачиваем в метод `compose`, тогда билдеры будут
обновляться только когда пересчитается значение.

Например, делаем геттер `doubleCounter` который возвращает удвоенное значение `counter`.
Для этого используем метод `compose` в котором говорим, что значение надо
пересчитать при обновлении `counter` и задаём уникальный ключ в кеше `"doubleCounter"`:

```dart
class MyAppStore extends RStore {
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

С помощью `compose` можно вычислять, например, сумму массива или мапить/фильтровать элементы.

### setTimer, setTimeout, setInterval и killTimer

Для простоты работы с таймерами сделана функция `setTimer` - это обертка над `Timer`.
Все созданные таймеры сами отменяются при уничтожении сторы, не нужно самим хранить
экземпляры таймеров и самим следить за `dispose`.

```dart
setTimer(
  duration: const Duration(seconds: 2),
  onTimer: () => setStore(() {
    showNextScreen = true;
  }),
);
```

Разные таймеры можно создавать, если задать разный `timerId`.
Если задать один и тотже `timerId`, то таймер перезапустится
(старый таймер будет отменен и за место него будет создан новый).

```dart
setTimer(
  duration: const Duration(seconds: 2),
  onTimer: () => setStore(() {
    showNextScreen = true;
  }),
  timerId: 1,
);

setTimer(
  duration: const Duration(seconds: 1),
  onTimer: () => setStore(() {
    showHello = true;
  }),
  timerId: 2,
);
```

Для того чтобы еще упростить создание таймеров сделаны функции `setTimeout` и `setInterval`:

```dart
setTimeout(
  () => setStore(() {
    showNextScreen = true;
  }),
  2000,
);

setInterval(
  () => setStore(() {
    counter++;
  }),
  1000,
);
```

В них не надо указывать имена входящим параметрам, не надо создавать Duration -
он всегда в миллисекундах, не надо указывать параметр `periodic`.
`setTimeout` - одноразовый таймер, `setInterval` - периодический.
Синтаксис такой же ка в JavaScript.

Таймеры можно отменять и вручную по `timerId` в `killTimer` если это требуется.

## Сниппеты кода

Чтобы было ещё удобнее с этим работать рекомендую добавить сниппеты кода:

### Android Studio - Life Template

```dart
import 'package:flutter/material.dart';
import 'package:reactive_store/reactive_store.dart';

class $STORE_NAME$ extends RStore {
  // TODO: add data here...

  @override
  $WIDGET_NAME$ get widget => super.widget as $WIDGET_NAME$;

  static $STORE_NAME$ of(BuildContext context) {
    return RStoreWidget.store<$STORE_NAME$>(context);
  }
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
- `STORE_NAME` - равно `regularExpression(concat(WIDGET_NAME, "Store"), "^__", "_")` + skip if defined
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
      "class $1Store extends RStore {",
      "\t// TODO: add data here...",
      "",
      "\t@override",
      "\t$1 get widget => super.widget as $1;",
      "}",
      "",
      "\tstatic $1Store of(BuildContext context) {",
      "\t\treturn RStoreWidget.store<$1Store>(context);",
      "\t}",
      "",
      "class ${1:MyWidget} extends RStoreWidget<$1Store> {",
      "\tconst $1({",
      "\t\tKey? key,",
      "\t}) : super(key: key);",
      "",
      "\t@override",
      "\t$1Store createRStore() => $1Store();",
      "",
      "\t@override",
      "\tWidget build(BuildContext context, $1Store store) {",
      "\t\treturn Container($0);",
      "\t}",
      "}",
      "",
    ]
  }
}
```

## Хорошие практики

**Один "сложный" widget = один стор!** Если потребовалось подключать много сторов -
значит вам нужно вынести часть подвиджетов в отдельный "сложный" widget.
"Сложный" виджет наследуем от RStoreWidget.

**В сторе не делаем функции/методы на получение информации!** Информацию из хранилища получаем
только напрямую из переменных или геттеров. Если нужно как-то обработать данные
перед выводом - делаем геттер и оборачиваем в `compose`.

**Публичные функции/методы сторы только на мутацию данных!** И методы эти не должны что-то
возвращать. Остальную логику скрывать в приватных функциях.

**id таймеров/подписок задавать константами в сторе!** Лучше задать всё в одном
месте и использовать от туда, чем копировать одинаковый текст или магические числа по коду.

**Пересоздавайте объекты/мапы/листы в сторе вместо их мутации!** Watch билдеры сравнивают
сложные объекты по ссылке если у них не переопределен оператор равенства. Они просто не
узнают что что-то внутри объекта изменилось. Для совсем сложной логики и данных можно использовать
именованные билдеры, но лучше от этой практики воздерживаться.

## Как это сделано

Под капотом это использует обычную механику Flatter`а:

- RStore - создает стримы которые пушатся по setStore
- Билдеры - это StatefulWidget`ы которые подписываются на стримы из RStore
- Если watch лист изменился то вызывается setState и происходит ребилд (сравнение элементов в watch происходит по ссылке - по этому в RStore надо перезаписывать объект, чтобы подхватилось изменения)
- RStoreWidget оборачивает RStore в InheritedWidget и добавляет себя в RStore.widget
