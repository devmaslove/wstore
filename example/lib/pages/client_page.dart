import 'package:example/store/clients_store.dart';
import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class ClientPageStore extends WStore {
  int get clientsCount => computed(
        watch: () => [clients],
        getValue: () => clients.length,
        keyName: 'clientsCount',
      );

  List<Client> get clients => computedFromStore(
        store: ClientsStore(),
        getValue: (ClientsStore store) => store.arrClients,
        keyName: 'clients',
      );

  void deleteClient(final Client client) {
    ClientsStore().removeItem(client);
  }

  Client addClient() {
    return ClientsStore().addItem(name: ClientsStore().getRandomName());
  }

  @override
  ClientPage get widget => super.widget as ClientPage;
}

class ClientPage extends WStoreWidget<ClientPageStore> {
  const ClientPage({
    super.key,
  });

  @override
  ClientPageStore createWStore() => ClientPageStore();

  @override
  Widget build(BuildContext context, ClientPageStore store) {
    return Scaffold(
      appBar: AppBar(
        title: WStoreValueBuilder<ClientPageStore, int>(
          store: store,
          watch: (store) => store.clientsCount,
          builder: (context, count) {
            return Text(
              'Clients count: $count',
            );
          },
        ),
      ),
      body: WStoreValueBuilder(
        store: store,
        watch: (ClientPageStore store) => store.clients,
        builder: (context, List<Client> clients) {
          return ListView.builder(
            itemCount: clients.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == clients.length) {
                return ListTile(
                  key: const Key('Add new client'),
                  title: const Text('+ Add new client'),
                  onTap: () {
                    final newClient = store.addClient();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${newClient.name} is added")),
                    );
                  },
                );
              }
              final client = clients[index];
              return ListTile(
                key: Key(client.id.toString()),
                title: Text(client.name),
                onTap: () {
                  store.deleteClient(client);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${client.name} is removed")),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
