import 'dart:math';

import 'package:wstore/wstore.dart';

class Client {
  final int id;
  final String name;

  const Client({
    required this.id,
    required this.name,
  });
}

class ClientsArray with GStoreChangeObjectMixin {
  final List<Client> _list = [];

  ClientsArray();

  void add(Client client) {
    final itemIndex = _list.indexWhere((item) => item.id == client.id);
    if (itemIndex != -1) {
      _list.removeAt(itemIndex);
      _list.insert(itemIndex, client);
    } else {
      _list.add(client);
    }
    incrementObjectChangeCount();
  }

  void remove(Client client) {
    if (_list.remove(client)) {
      incrementObjectChangeCount();
    }
  }

  void removeById(int id) {
    final oldLength = _list.length;
    _list.removeWhere((item) => item.id == id);
    if (oldLength != _list.length) {
      incrementObjectChangeCount();
    }
  }

  Client? getById(int id) {
    final index = _list.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    return _list[index];
  }

  int getNextId() {
    final maxId = _list.fold<int>(
      0,
      (maxId, client) => client.id > maxId ? client.id : maxId,
    );
    return maxId + 1;
  }

  int get length => _list.length;

  operator [](int index) => _list[index];
}

class ClientsStore extends GStore {
  static ClientsStore? _instance;

  factory ClientsStore() => _instance ??= ClientsStore._();

  final _random = Random();

  ClientsStore._() {
    for (int i = 0; i < 3; i++) {
      final name = getRandomName();
      final client = Client(
        id: i + 1,
        name: name,
      );
      arrClients.add(client);
    }
  }

  String getRandomName() {
    const firstNames = [
      'Alice',
      'Bob',
      'Charlie',
      'David',
      'Emily',
      'Frank',
      'Grace',
      'Henry',
      'Isabella',
      'Jack',
      'Kate',
      'Liam',
      'Mia',
      'Nathan',
      'Olivia',
      'Peter',
      'Quinn',
      'Rachel',
      'Sophia',
      'Thomas',
    ];
    return firstNames[_random.nextInt(firstNames.length)];
  }

  final ClientsArray arrClients = ClientsArray();

  Client addItem({
    required final String name,
  }) {
    final nextId = arrClients.getNextId();
    final newClient = Client(
      id: nextId,
      name: name,
    );
    setStore(() {
      arrClients.add(newClient);
    });
    return newClient;
  }

  void removeFromItemsById(final int id) {
    setStore(() {
      arrClients.removeById(id);
    });
  }

  void removeItem(final Client item) {
    setStore(() {
      arrClients.remove(item);
    });
  }

  Client? getItemById(final int id) {
    return arrClients.getById(id);
  }
}
