import 'package:example/pages/client_page.dart';
import 'package:example/pages/counter_page.dart';
import 'package:example/pages/debounce_page.dart';
import 'package:example/pages/http_get_page.dart';
import 'package:example/pages/splash_screen_page.dart';
import 'package:example/pages/states_rebuilder_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WStore examples')),
      body: const MainPageContent(),
    );
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'States re-builder',
          page: () => const StatesReBuilderPage(),
        ),
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'Splash screen',
          page: () => const SplashScreenPage(),
        ),
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'Counter (default app)',
          page: () => const CounterPage(),
        ),
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'Debounce search',
          page: () => const DebouncePage(),
        ),
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'Http get',
          page: () => const HttpGetPage(),
        ),
        const SizedBox(height: 20),
        ButtonGoToPage(
          text: 'Clients from repository',
          page: () => const ClientPage(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ButtonGoToPage extends StatelessWidget {
  final String text;
  final Widget Function() page;

  const ButtonGoToPage({
    super.key,
    required this.text,
    required this.page,
  });

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
