import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class HttpGetPageStore extends WStore {
  final _dio = Dio();

  String get affirmation => computedConverter<Response, String>(
        future: _dio.get('https://www.affirmations.dev/'),
        getValue: (response) {
          return response.data?['affirmation'] ?? '';
        },
        initialValue: '',
        keyName: 'affirmation',
        onError: (error, stack) => debugPrint(error.toString()),
      );
}

class HttpGetPage extends WStoreWidget<HttpGetPageStore> {
  const HttpGetPage({super.key});

  @override
  HttpGetPageStore createWStore() => HttpGetPageStore();

  @override
  Widget build(BuildContext context, HttpGetPageStore store) {
    return Scaffold(
      appBar: AppBar(title: const Text('Http get Affirmation')),
      body: const SafeArea(child: HttpGetPageContent()),
    );
  }
}

class HttpGetPageContent extends StatelessWidget {
  const HttpGetPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: WStoreValueBuilder<HttpGetPageStore, String>(
        watch: (store) => store.affirmation,
        builder: (context, affirmation) {
          return Text(
            affirmation,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}
