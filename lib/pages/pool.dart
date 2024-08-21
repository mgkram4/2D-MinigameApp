import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class PoolGame extends StatefulWidget {
  @override
  _PoolGameState createState() => _PoolGameState();
}

class _PoolGameState extends State<PoolGame> {
  int score = 0;
  bool gameRunning = false;
  Timer? gameTimer;
  int timeLeft = 60;

  List<Ball> balls = [];
  late Ball cueBall;
  List<Rect> pockets = [];

  Offset? dragStart;
  Offset? dragCurrent;

  @override
  void initState() {
    super.initState();
    resetBalls();
    setupPockets();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void setupPockets() {
    double pocketRadius = 15;
    pockets = [
      Rect.fromCircle(center: Offset(0, 0), radius: pocketRadius),
      Rect.fromCircle(center: Offset(300, 0), radius: pocketRadius),
      Rect.fromCircle(center: Offset(0, 500), radius: pocketRadius),
      Rect.fromCircle(center: Offset(300, 500), radius: pocketRadius),
      Rect.fromCircle(center: Offset(0, 250), radius: pocketRadius),
      Rect.fromCircle(center: Offset(300, 250), radius: pocketRadius),
    ];
  }

  void resetBalls() {
    balls = [];
    double startX = 150;
    double startY = 125;
    double ballRadius = 10;
    double rowSpacing = ballRadius * 2 * sin(pi / 3);
    double colSpacing = ballRadius * 2;

    List<List<int>> rackPattern = [
      [1],
      [2, 3],
      [4, 5, 6],
      [7, 8, 9, 10],
      [11, 12, 13, 14, 15]
    ];

    for (int row = 0; row < rackPattern.length; row++) {
      for (int col = 0; col < rackPattern[row].length; col++) {
        int ballNumber = rackPattern[row][col];
        double x =
            startX + (col - rackPattern[row].length / 2 + 0.5) * colSpacing;
        double y = startY +
            (rackPattern.length - 1 - row) * rowSpacing; // Flipped Y-coordinate
        balls.add(Ball(ballNumber, Offset(x, y)));
      }
    }

    cueBall = Ball(0, Offset(150, 375));
  }

  void startGame() {
    setState(() {
      score = 0;
      gameRunning = true;
      timeLeft = 60;
      resetBalls();
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft == 0) {
          gameRunning = false;
          gameTimer?.cancel();
          _showEndGameDialog('Your score: $score');
        }
      });
    });
  }

  void hitCueBall() {
    if (!gameRunning || dragStart == null || dragCurrent == null) return;

    Offset dragVector = dragStart! - dragCurrent!;
    double power = dragVector.distance * 5.0; // Increased power factor
    double angle = atan2(dragVector.dy, dragVector.dx);

    cueBall.velocity = Offset(power * cos(angle), power * sin(angle));

    _simulatePhysics();
  }

  void _simulatePhysics() {
    const double friction = 0.98;
    const int steps = 100;

    Timer.periodic(Duration(milliseconds: 16), (timer) {
      bool stillMoving = false;

      for (int i = 0; i < steps; i++) {
        for (Ball ball in [cueBall, ...balls]) {
          if (ball.velocity.distance > 0.1) {
            stillMoving = true;
            ball.position += ball.velocity / steps.toDouble();
            ball.velocity *= friction;

            // Check for collisions with walls
            if (ball.position.dx < 10 || ball.position.dx > 290) {
              ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
            }
            if (ball.position.dy < 10 || ball.position.dy > 490) {
              ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
            }

            // Check for collisions with other balls
            for (Ball otherBall in [cueBall, ...balls]) {
              if (ball != otherBall) {
                Offset distanceVector = ball.position - otherBall.position;
                double distance = distanceVector.distance;
                if (distance < 20) {
                  // 20 is the sum of the radii of two balls
                  Offset normal = distanceVector / distance;

                  // Calculate the tangent vector
                  Offset tangent = Offset(-normal.dy, normal.dx);

                  // Project velocities onto the normal and tangent
                  double v1n = ball.velocity.dot(normal);
                  double v1t = ball.velocity.dot(tangent);
                  double v2n = otherBall.velocity.dot(normal);
                  double v2t = otherBall.velocity.dot(tangent);

                  // Swap the normal velocities
                  double temp = v1n;
                  v1n = v2n;
                  v2n = temp;

                  // Convert the scalar normal and tangential velocities back into vectors
                  ball.velocity = normal * v1n + tangent * v1t;
                  otherBall.velocity = normal * v2n + tangent * v2t;

                  // Move balls apart to prevent sticking
                  double overlap = 20 - distance;
                  ball.position += normal * (overlap / 2);
                  otherBall.position -= normal * (overlap / 2);
                }
              }
            }

            // Check for pocketed balls
            for (Rect pocket in pockets) {
              if (pocket.contains(ball.position)) {
                if (ball != cueBall) {
                  balls.remove(ball);
                  score++;
                } else {
                  cueBall.position = Offset(150, 375);
                  cueBall.velocity = Offset.zero;
                }
                break;
              }
            }
          }
        }
      }

      setState(() {});

      if (!stillMoving) {
        timer.cancel();
        if (balls.isEmpty) {
          _showEndGameDialog(
              'Congratulations! You pocketed all balls!\nFinal score: $score');
        }
      }
    });
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
                Navigator.pop(context);
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
      appBar: AppBar(title: Text('Pool Game')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time Left: $timeLeft', style: TextStyle(fontSize: 24.0)),
            Text('Score: $score', style: TextStyle(fontSize: 24.0)),
            GestureDetector(
              onPanStart: (details) {
                if (!gameRunning) return;
                setState(() {
                  dragStart = details.localPosition;
                  dragCurrent = dragStart;
                });
              },
              onPanUpdate: (details) {
                if (!gameRunning) return;
                setState(() {
                  dragCurrent = details.localPosition;
                });
              },
              onPanEnd: (details) {
                if (!gameRunning) return;
                hitCueBall();
                setState(() {
                  dragStart = null;
                  dragCurrent = null;
                });
              },
              child: Container(
                width: 300,
                height: 500,
                color: Colors.green[800],
                child: CustomPaint(
                  painter: PoolTablePainter(
                      balls, cueBall, pockets, dragStart, dragCurrent),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: gameRunning ? null : startGame,
              child: Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class Ball {
  final int number;
  Offset position;
  Offset velocity = Offset.zero;

  Ball(this.number, this.position);
}

class PoolTablePainter extends CustomPainter {
  final List<Ball> balls;
  final Ball cueBall;
  final List<Rect> pockets;
  final Offset? dragStart;
  final Offset? dragCurrent;

  PoolTablePainter(
      this.balls, this.cueBall, this.pockets, this.dragStart, this.dragCurrent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw pockets
    paint.color = Colors.black;
    for (var pocket in pockets) {
      canvas.drawOval(pocket, paint);
    }

    // Draw balls
    for (var ball in balls) {
      paint.color = Colors.primaries[ball.number % Colors.primaries.length];
      canvas.drawCircle(ball.position, 10, paint);
      TextPainter(
        text: TextSpan(
          text: '${ball.number}',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, ball.position + Offset(-6, -6));
    }

    // Draw cue ball
    paint.color = Colors.white;
    canvas.drawCircle(cueBall.position, 10, paint);

    // Draw drag line
    if (dragStart != null && dragCurrent != null) {
      paint.color = Colors.white;
      paint.strokeWidth = 2;
      canvas.drawLine(cueBall.position, dragCurrent!, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension OffsetX on Offset {
  double dot(Offset other) => dx * other.dx + dy * other.dy;
}
