import 'package:flutter/material.dart';
import 'package:game_1/pages/dashboard.dart';
import 'package:game_1/pages/memory.dart';
import 'package:game_1/pages/pool.dart';
import 'package:game_1/pages/tic_tak_toe.dart';
import 'package:game_1/pages/wack_a_mole.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Games',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner:
          false, // Add this line to turn off the debug banner
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardPage(),
        '/memory-game': (context) => Memory(),
        '/whack-a-mole': (context) => WhackAMole(),
        '/tic-tac-toe': (context) => TicTacToe(),
        "/pool-game": (context) => PoolGame(),
      },
    );
  }
}
