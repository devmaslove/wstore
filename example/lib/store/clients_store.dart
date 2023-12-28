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

  List<Client> arrClients = [];


  void setItems(final List<Client> items) {
    setStore(() {
      arrClients = [...items];
    });
  }

  Client addItem({
    required final String name,
  }) {
    final maxId = arrClients.fold<int>(
      0,
          (maxId, client) => client.id > maxId ? client.id : maxId,
    );
    final newClient = Client(
      id: maxId + 1,
      name: name,
    );
    addItemOrReplaceById(newClient);
    return newClient;
  }

  void addItemOrReplaceById(final Client newItem) {
    final items = [...arrClients];
    final itemIndex = items.indexWhere((item) => item.id == newItem.id);
    if (itemIndex != -1) {
      items.removeAt(itemIndex);
      items.insert(itemIndex, newItem);
    } else {
      items.add(newItem);
    }
    setItems(items);
  }

  void removeFromItemsById(final int id) {
    final items = [...arrClients];
    items.removeWhere((item) => item.id == id);
    setItems(items);
  }

  void removeItem(final Client item) {
    final items = [...arrClients];
    items.remove(item);
    setItems(items);
  }

  Client? getItemById(final int id) {
    final index = arrClients.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    return arrClients[index];
  }
}