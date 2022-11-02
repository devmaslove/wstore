import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class DebouncePageStore extends WStore {
  static const _timerIdSearchText = 0;
  String searchText = '';
  String inputText = '';

  bool get isEmptyInputText => computed<bool>(
        getValue: () => inputText.isEmpty,
        watch: () => [inputText],
        keyName: "isEmptyInputText",
      );

  void setSearchText(String text) {
    setStore(() {
      inputText = text;
      searchText = '...';
    });
    setTimeout(() {
      setStore(() => searchText = text);
    }, 500, _timerIdSearchText);
  }
}

class DebouncePage extends WStoreWidget<DebouncePageStore> {
  const DebouncePage({super.key});

  @override
  Widget build(BuildContext context, DebouncePageStore store) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debounce search')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              WStoreValueBuilder<DebouncePageStore, String>(
                store: store,
                watch: (store) => store.searchText,
                builder: (context, text) {
                  return Text(text);
                },
              ),
              const SizedBox(height: 20),
              WStoreValueBuilder<DebouncePageStore, bool>(
                store: store,
                watch: (store) => store.isEmptyInputText,
                builder: (context, isEmpty) {
                  return _SearchField(
                    onChanged: store.setSearchText,
                    isEmpty: store.isEmptyInputText,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  DebouncePageStore createWStore() => DebouncePageStore();
}

class _SearchField extends StatelessWidget {
  final void Function(String) onChanged;
  final bool isEmpty;

  const _SearchField({
    required this.onChanged,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 16,
        height: 18 / 16,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black12,
        contentPadding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 15,
          bottom: 17,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            top: 15,
            right: 16,
            bottom: 17,
          ),
          child: Icon(
            Icons.search,
            size: 18,
            color: isEmpty ? Colors.grey : Colors.black,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          gapPadding: 0,
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          fontSize: 16,
          height: 18 / 16,
          color: Colors.grey,
        ),
        hintText: 'Search',
      ),
    );
  }
}
