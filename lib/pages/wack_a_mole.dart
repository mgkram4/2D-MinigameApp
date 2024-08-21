import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class WhackAMole extends StatefulWidget {
  @override
  _WhackAMoleState createState() => _WhackAMoleState();
}

class _WhackAMoleState extends State<WhackAMole> {
  int score = 0;
  int moleIndex = -1; // Initialized to -1 to ensure it's not a valid grid index
  bool gameRunning = false;
  Timer? gameTimer;
  Timer? moleTimer;
  int timeLeft = 30;

  @override
  void dispose() {
    gameTimer?.cancel();
    moleTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      score = 0;
      gameRunning = true;
      timeLeft = 30;
      moleIndex = Random().nextInt(9); // Initialize moleIndex at game start
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft == 0) {
          gameRunning = false;
          gameTimer?.cancel();
          moleTimer?.cancel();
          _showEndGameDialog('Your score: $score');
        }
      });
    });

    startMoleMovement();
  }

  void startMoleMovement() {
    moleTimer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      setState(() {
        moleIndex = Random().nextInt(9); // Randomly change the mole's position
      });
    });
  }

  void whackMole(int index) {
    if (gameRunning && index == moleIndex) {
      setState(() {
        score++;
        moleIndex = Random().nextInt(
            9); // Change mole position immediately after a successful hit
      });
    }
  }

  void _showEndGameDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
            ),
            TextButton(
              child: Text('Back to Dashboard'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Return to the dashboard
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Whack-a-Mole')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Time Left: $timeLeft', style: TextStyle(fontSize: 24.0)),
          Text('Score: $score', style: TextStyle(fontSize: 24.0)),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.all(20.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => whackMole(index),
                child: Card(
                  color: index == moleIndex ? Colors.green : Colors.blue,
                  child: Center(
                    child: Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 64.0,
                    ),
                  ),
                ),
              );
            },
          ),
          if (!gameRunning)
            ElevatedButton(
              onPressed: startGame,
              child: Text('Start Game'),
            ),
        ],
      ),
    );
  }
}
