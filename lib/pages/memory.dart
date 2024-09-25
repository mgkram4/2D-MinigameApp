import 'dart:async';

import 'package:flutter/material.dart';

class Memory extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Memory> {
  List<String> cardValues = [];
  List<bool> cardFlips = [];
  int previousIndex = -1;
  bool flip = false;
  int matchesFound = 0;
  Stopwatch stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    setupGame();
    stopwatch.start();
  }

  void setupGame() {
    cardValues = ['A', 'A', 'B', 'B', 'C', 'C', 'D', 'D', 'E', 'E', 'F', 'F'];
    cardValues.shuffle();
    cardFlips = List.generate(cardValues.length, (index) => false);
    matchesFound = 0;
    previousIndex = -1;
    stopwatch.reset();
  }

  void handleCardTap(int index) {
    if (!flip && !cardFlips[index]) {
      setState(() {
        cardFlips[index] = !cardFlips[index];
        if (previousIndex == -1) {
          previousIndex = index;
        } else {
          flip = true;
          if (cardValues[previousIndex] != cardValues[index]) {
            Timer(Duration(milliseconds: 500), () {
              setState(() {
                cardFlips[previousIndex] = false;
                cardFlips[index] = false;
                flip = false;
                previousIndex = -1;
              });
            });
          } else {
            matchesFound++;
            flip = false;
            previousIndex = -1;
            if (matchesFound == cardValues.length ~/ 2) {
              stopwatch.stop();
              _showEndGameDialog();
            }
          }
        }
      });
    }
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text(
              'You completed the game in ${stopwatch.elapsed.inSeconds} seconds!'),
          actions: <Widget>[
            TextButton(
              child: Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  setupGame();
                  stopwatch.start();
                });
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
      body: GridView.builder(
        padding: EdgeInsets.all(20.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: cardValues.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => handleCardTap(index),
            child: Card(
              color: cardFlips[index] ? Colors.white : Colors.blue,
              child: Center(
                child: Text(
                  cardFlips[index] ? cardValues[index] : '',
                  style: TextStyle(fontSize: 32.0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
