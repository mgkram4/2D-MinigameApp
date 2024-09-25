import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_1/pages/basketball.dart';
import 'package:game_1/pages/darts.dart';
import 'package:game_1/pages/dashboard.dart';
import 'package:game_1/pages/golf.dart';
import 'package:game_1/pages/memory.dart';
import 'package:game_1/pages/pool.dart';
import 'package:game_1/pages/push.dart';
import 'package:game_1/pages/shooter.dart';
import 'package:game_1/pages/tic_tak_toe.dart';
import 'package:game_1/pages/wack_a_mole.dart';
import 'package:game_1/pages/welcome.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 4,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(), // Change this to WelcomePage
        '/dashboard': (context) => DashboardPage(), // Add this new route
        '/memory-game': (context) => GameWrapper(child: Memory()),
        '/whack-a-mole': (context) => GameWrapper(child: WhackAMole()),
        '/tic-tac-toe': (context) => GameWrapper(child: TicTacToe()),
        '/pool-game': (context) => PoolGameWidget(),
        '/golf-game': (context) => GolfGameWidget(),
        '/dart-game': (context) => GameWrapper(
            child: GameWidget(game: DartsGame()), gameTitle: 'Dart Game'),
        '/basketball-game': (context) => GameWrapper(
            child: BasketballGameWidget(), gameTitle: 'Basketball Game'),
        '/sumo-game': (context) => KnockoutGameWidget(),
        '/space-shooter': (context) => ShooterGameWidget(),
      },
    );
  }
}

class PoolGameWidget extends StatelessWidget {
  const PoolGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameTitle: 'Pool Game',
      child: GameWidget(
        game: PoolGame(
          onPlayAgain: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PoolGameWidget()),
            );
          },
          onExit: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
    );
  }
}

class GolfGameWidget extends StatelessWidget {
  const GolfGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameTitle: 'Golf Game',
      child: GameWidget(
        game: GolfGame(
          onPlayAgain: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GolfGameWidget()),
            );
          },
          onExit: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
    );
  }
}

class KnockoutGameWidget extends StatelessWidget {
  const KnockoutGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameTitle: 'Sumo Game',
      child: GameWidget(
        game: KnockoutGame(
          onPlayAgain: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => KnockoutGameWidget()),
            );
          },
          onExit: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
    );
  }
}

class ShooterGameWidget extends StatelessWidget {
  const ShooterGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWrapper(
      gameTitle: 'DuckShootingGame',
      child: GameWidget(
        game: DuckShootingGame(
          onPlayAgain: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ShooterGameWidget()),
            );
          },
          onExit: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
    );
  }
}

class GameWrapper extends StatelessWidget {
  final Widget child;
  final String gameTitle;

  const GameWrapper({super.key, required this.child, this.gameTitle = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: gameTitle),
      body: child,
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color textColor;

  const CustomAppBar(
      {super.key, required this.title, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      foregroundColor: textColor,
      leading: IconButton(
        icon: const Icon(Icons.home),
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed('/dashboard'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User profile not implemented yet')),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(30);
}
