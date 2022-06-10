import 'package:example/pages/states_rebuilder_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RStore examples')),
      body: const MainPageContent(),
    );
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'States re-builder',
          page: () => const StatesReBuilderPage(),
        ),
      ],
    );
  }
}

class ButtonGoToPage extends StatelessWidget {
  final String text;
  final Widget Function() page;

  const ButtonGoToPage({
    Key? key,
    required this.text,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => page(),
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(50, 50),
        ),
        child: Text(text),
      ),
    );
  }
}
