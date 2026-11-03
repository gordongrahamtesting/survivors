import 'package:flutter/material.dart';

import 'game_screen.dart';

void main() => runApp(const GrandpaSurvivors());

class GrandpaSurvivors extends StatelessWidget {
  const GrandpaSurvivors({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grampa Survivors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff11151b),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe6a84d),
          brightness: Brightness.dark,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class MyApp extends GrandpaSurvivors {
  const MyApp({super.key});
}
