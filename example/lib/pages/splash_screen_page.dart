import 'package:flutter/material.dart';
import 'package:wstore/wstore.dart';

class SplashScreenPageStore extends WStore {
  static const _timerIdNextScreen = 0;
  bool showNextScreen = false;

  startTimerNextPage() {
    setTimer(
      duration: const Duration(seconds: 2),
      timerId: _timerIdNextScreen,
      onTimer: () => setStore(() {
        showNextScreen = true;
      }),
    );
  }

  @override
  SplashScreenPage get widget => super.widget as SplashScreenPage;
}

class SplashScreenPage extends WStoreWidget<SplashScreenPageStore> {
  const SplashScreenPage({
    super.key,
  });

  @override
  initWStore(store) => store.startTimerNextPage();

  @override
  Widget build(BuildContext context, SplashScreenPageStore store) {
    return Scaffold(
      appBar: AppBar(title: const Text('Splash screen')),
      body: Center(
        child: WStoreBoolListener<SplashScreenPageStore>(
          store: store,
          watch: (store) => store.showNextScreen,
          onTrue: (context) => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => const _NextPage(),
            ),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  SplashScreenPageStore createWStore() => SplashScreenPageStore();
}

class _NextPage extends StatelessWidget {
  const _NextPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ),
    );
  }
}
