import 'package:example/store/clients_store.dart';
import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

// error message should be done similarly
enum ClientPageMessageEnum { added, removed }

class ClientPageMessage {
  final ClientPageMessageEnum message;
  final String clientName;

  const ClientPageMessage({required this.message, required this.clientName});
}

class ClientPageStore extends WStore {
  ClientPageMessage? message;

  ClientsArray get clients => computedFromStore(
        store: ClientsStore(),
        getValue: (ClientsStore store) => store.arrClients,
        keyName: 'clients',
      );

  int get clientsCount => computed(
        watch: () => [clients],
        getValue: () => clients.length,
        keyName: 'clientsCount',
      );

  void deleteClient(final Client client) {
    ClientsStore().removeItem(client);
    setStore(() {
      message = ClientPageMessage(
        message: ClientPageMessageEnum.removed,
        clientName: client.name,
      );
    });
  }

  void addClient() {
    final newClient = ClientsStore().addItem(
      name: ClientsStore().getRandomName(),
    );
    setStore(() {
      message = ClientPageMessage(
        message: ClientPageMessageEnum.added,
        clientName: newClient.name,
      );
    });
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
      body: WStoreValueListener<ClientPageStore, ClientPageMessage?>(
        store: store,
        watch: (store) => store.message,
        onChange: (context, message) {
          if (message == null) return;
          final text = localizeMessage(
            context,
            message.message,
            message.clientName,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(text)),
          );
        },
        child: const ClientsPageBody(),
      ),
    );
  }

  String localizeMessage(
    BuildContext context,
    ClientPageMessageEnum message,
    String clientName,
  ) {
    // here get your localization from context
    switch (message) {
      case ClientPageMessageEnum.added:
        return '$clientName was added';
      case ClientPageMessageEnum.removed:
        return '$clientName was removed';
    }
  }
}

class ClientsPageBody extends StatelessWidget {
  const ClientsPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return WStoreBuilder<ClientPageStore>(
      watch: (store) => [store.clients],
      builder: (context, store) {
        final clients = store.clients;
        return ListView.builder(
          itemCount: clients.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == clients.length) {
              return ListTile(
                key: const Key('Add new client'),
                title: const Text('+ Add new client'),
                onTap: () => store.addClient(),
              );
            }
            final client = clients[index];
            return ListTile(
              key: Key(client.id.toString()),
              title: Text(client.name),
              onTap: () => store.deleteClient(client),
            );
          },
        );
      },
    );
  }
}
