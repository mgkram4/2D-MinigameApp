import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum BallType { solid, striped, cue, eight }

class PoolGame extends FlameGame with DragCallbacks, TapCallbacks {
  late double tableWidth;
  late double tableHeight;
  late double ballRadius;
  late double pocketRadius;
  late double cushionWidth;

  late Ball cueBall;
  List<Ball> balls = [];
  List<Vector2> pockets = [];

  Vector2 dragStart = Vector2.zero();
  Vector2 dragEnd = Vector2.zero();

  bool gameOver = false;
  bool isPlayerTurn = true;
  BallType? playerBallType;
  BallType? botBallType;

  late ShootingLine shootingLine;
  late TextComponent playerTargetComponent;
  late TextComponent botTargetComponent;
  late TextComponent turnComponent;
  late TextComponent gameOverText;
  late TextComponent playAgainText;
  late TextComponent exitText;
  late TextComponent eightBallNextComponent;

  late Sprite tableSprite;

  final Function() onPlayAgain;
  final Function() onExit;

  PoolGame({required this.onPlayAgain, required this.onExit});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    tableSprite = await loadSprite('poolTable.png');
    tableWidth = size.x;
    tableHeight = size.y;

    // Calculate relative dimensions
    ballRadius = tableWidth * 0.02;
    pocketRadius = tableWidth * 0.05;
    cushionWidth = tableWidth * 0.13;

    add(SpriteComponent(
        sprite: tableSprite, size: Vector2(tableWidth, tableHeight)));

    setupPockets();
    resetBalls();
    balls.forEach(add);
    add(cueBall);
    pockets.forEach((pocket) =>
        add(PocketComponent(position: pocket, radius: pocketRadius)));

    shootingLine = ShootingLine();
    add(shootingLine);

    playerTargetComponent = TextComponent(
      position: Vector2(10, 10),
      text: 'Player: ?',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(playerTargetComponent);

    botTargetComponent = TextComponent(
      position: Vector2(10, 40),
      text: 'Bot: ?',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(botTargetComponent);

    turnComponent = TextComponent(
      position: Vector2(10, 70),
      text: 'Player\'s turn',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(turnComponent);

    eightBallNextComponent = TextComponent(
      position: Vector2(10, 100),
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.yellow, fontSize: 20),
      ),
    );
    add(eightBallNextComponent);

    gameOverText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2 - 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 40),
      ),
    );

    playAgainText = TextComponent(
      text: 'Play Again',
      position: Vector2(size.x / 2, size.y / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 30),
      ),
    );

    exitText = TextComponent(
      text: 'Exit',
      position: Vector2(size.x / 2, size.y / 2 + 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 30),
      ),
    );

    hideGameOverComponents();
  }

  void setupPockets() {
    double padding = pocketRadius;
    pockets = [
      Vector2(cushionWidth - 10, cushionWidth), // Top left
      Vector2(tableWidth - cushionWidth - 20, cushionWidth), // Top right
      Vector2(-20 + cushionWidth, -20 + tableHeight / 2), // Middle left
      Vector2(-20 + tableWidth - cushionWidth,
          -20 + tableHeight / 2), // Middle right
      Vector2(
          -20 + cushionWidth, tableHeight - cushionWidth - 40), // Bottom left
      Vector2(-35 + tableWidth - cushionWidth,
          tableHeight - cushionWidth - 40), // Bottom right
    ];
  }

  void resetBalls() {
    balls.clear();
    double startX = tableWidth / 2;
    double startY = tableHeight / 3;
    double rowSpacing = ballRadius * 2 * sin(pi / 3);
    double colSpacing = ballRadius * 2;

    List<List<int>> rackPattern = [
      [1, 9, 10, 11, 12],
      [13, 14, 2, 3],
      [4, 15, 5],
      [6, 7],
      [8]
    ];

    for (int row = 0; row < rackPattern.length; row++) {
      for (int col = 0; col < rackPattern[row].length; col++) {
        int ballNumber = rackPattern[row][col];
        double x =
            startX + (col - rackPattern[row].length / 2 + 0.5) * colSpacing;
        double y = startY + row * rowSpacing;
        BallType type = ballNumber == 8
            ? BallType.eight
            : (ballNumber % 2 == 0 ? BallType.striped : BallType.solid);
        balls.add(Ball(ballNumber, Vector2(x, y), type, ballRadius));
      }
    }

    cueBall = Ball(0, Vector2(tableWidth / 2, tableHeight * 3 / 4),
        BallType.cue, ballRadius);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameOver) {
      balls.forEach((ball) => ball.update(dt));
      cueBall.update(dt);
      checkCollisions(dt);
      checkPockets();

      updateTargetComponents();
      turnComponent.text = isPlayerTurn ? 'Player\'s turn' : 'Bot\'s turn';

      checkEightBallNext();

      if (balls.isEmpty || !balls.any((ball) => ball.type == BallType.eight)) {
        gameOver = true;
        showGameOver(isPlayerTurn ? 'Bot' : 'Player');
      } else if (!isPlayerTurn && allBallsStopped()) {
        botTurn();
      }
    }
  }

  void updateTargetComponents() {
    playerTargetComponent.text =
        'Player: ${playerBallType == BallType.solid ? 'Odd' : playerBallType == BallType.striped ? 'Odd' : '?'}';
    botTargetComponent.text =
        'Bot: ${botBallType == BallType.solid ? 'Even' : botBallType == BallType.striped ? 'Even' : '?'}';
  }

  void checkEightBallNext() {
    bool playerEightBallNext = playerBallType != null &&
        !balls.any((ball) => ball.type == playerBallType);
    bool botEightBallNext =
        botBallType != null && !balls.any((ball) => ball.type == botBallType);

    if (playerEightBallNext || botEightBallNext) {
      eightBallNextComponent.text = '8 Ball Next!';
    } else {
      eightBallNextComponent.text = '';
    }
  }

  void checkCollisions(double dt) {
    for (var ball in [cueBall, ...balls]) {
      // Wall collisions
      if (ball.position.x - ball.radius < cushionWidth ||
          ball.position.x + ball.radius > tableWidth - cushionWidth) {
        ball.velocity.x *= -0.9;
        ball.position.x = ball.position.x < cushionWidth + ball.radius
            ? cushionWidth + ball.radius
            : tableWidth - cushionWidth - ball.radius;
      }
      if (ball.position.y - ball.radius < cushionWidth ||
          ball.position.y + ball.radius > tableHeight - cushionWidth) {
        ball.velocity.y *= -0.9;
        ball.position.y = ball.position.y < cushionWidth + ball.radius
            ? cushionWidth + ball.radius
            : tableHeight - cushionWidth - ball.radius;
      }

      // Ball-to-ball collisions
      for (var otherBall in [cueBall, ...balls]) {
        if (ball != otherBall) {
          final Vector2 normal = otherBall.position - ball.position;
          final double distance = normal.length;
          if (distance <= ball.radius * 2) {
            normal.normalize();
            final Vector2 relativeVelocity = otherBall.velocity - ball.velocity;
            final double velocityAlongNormal = relativeVelocity.dot(normal);
            if (velocityAlongNormal > 0) continue;
            final double restitution = 0.9;
            final double impulseScalar =
                -(1 + restitution) * velocityAlongNormal / 2;
            final Vector2 impulse = normal * impulseScalar;
            ball.velocity -= impulse;
            otherBall.velocity += impulse;
            final double separation = (ball.radius * 2 - distance) / 2;
            ball.position -= normal * separation;
            otherBall.position += normal * separation;
          }
        }
      }
    }
  }

  void checkPockets() {
    for (var pocket in pockets) {
      for (var ball in [...balls, cueBall]) {
        if (ball.position.distanceTo(pocket) < pocketRadius + ball.radius) {
          if (ball != cueBall) {
            balls.remove(ball);
            remove(ball);
            if (ball.type == BallType.eight) {
              gameOver = true;
              if ((isPlayerTurn && playerBallType == null) ||
                  (!isPlayerTurn && botBallType == null) ||
                  (isPlayerTurn &&
                      balls.any((b) => b.type == playerBallType)) ||
                  (!isPlayerTurn && balls.any((b) => b.type == botBallType))) {
                showGameOver(isPlayerTurn ? 'Bot' : 'Player');
              } else {
                showGameOver(isPlayerTurn ? 'Player' : 'Bot');
              }
            } else {
              if (playerBallType == null && botBallType == null) {
                playerBallType = isPlayerTurn
                    ? ball.type
                    : (ball.type == BallType.solid
                        ? BallType.striped
                        : BallType.solid);
                botBallType = isPlayerTurn
                    ? (ball.type == BallType.solid
                        ? BallType.striped
                        : BallType.solid)
                    : ball.type;
              }
            }
          } else {
            cueBall.position
                .setFrom(Vector2(tableWidth / 2, tableHeight * 3 / 4));
            cueBall.velocity.setZero();
            switchTurn();
          }
        }
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (!gameOver &&
        isPlayerTurn &&
        cueBall.containsPoint(event.canvasPosition)) {
      dragStart = event.canvasPosition;
      dragEnd = dragStart;
      shootingLine.setVisible(true);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!gameOver && isPlayerTurn && dragStart != Vector2.zero()) {
      dragEnd = event.canvasPosition;
      final direction = dragStart - dragEnd;
      shootingLine.updateLine(cueBall.position, cueBall.position + direction);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!gameOver && isPlayerTurn && dragStart != Vector2.zero()) {
      final direction = dragStart - dragEnd;
      final strength = direction.length.clamp(0.0, 300.0);
      cueBall.velocity = direction.normalized() * strength * 2.0;
      dragStart = Vector2.zero();
      dragEnd = Vector2.zero();
      shootingLine.setVisible(false);
      switchTurn();
    }
  }

  void switchTurn() {
    isPlayerTurn = !isPlayerTurn;
  }

  bool allBallsStopped() {
    return balls.every((ball) => ball.velocity.length < 0.1) &&
        cueBall.velocity.length < 0.1;
  }

  void botTurn() {
    if (balls.isNotEmpty) {
      Ball targetBall;
      if (botBallType != null) {
        targetBall = balls.firstWhere((ball) => ball.type == botBallType,
            orElse: () =>
                balls.firstWhere((ball) => ball.type == BallType.eight));
      } else {
        targetBall = balls[Random().nextInt(balls.length)];
      }

      Vector2 direction = targetBall.position - cueBall.position;
      direction.normalize();

      // Improved bot logic
      double strength = 200 + Random().nextDouble() * 100;
      Vector2 aimPoint = targetBall.position + direction * ballRadius;
      Vector2 shotDirection = aimPoint - cueBall.position;
      shotDirection.normalize();

      cueBall.velocity = shotDirection * strength;

      switchTurn();
    }
  }

  void showGameOver(String winner) {
    gameOverText.text = 'Game Over! $winner wins!';
    showGameOverComponents();
  }

  void hideGameOverComponents() {
    gameOverText.removeFromParent();
    playAgainText.removeFromParent();
    exitText.removeFromParent();
  }

  void showGameOverComponents() {
    add(gameOverText);
    add(playAgainText);
    add(exitText);
  }

  void restartGame() {
    hideGameOverComponents();
    gameOver = false;
    isPlayerTurn = true;
    playerBallType = null;
    botBallType = null;
    resetBalls();
    balls.forEach(add);
    eightBallNextComponent.text = '';
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) {
      if (playAgainText.containsPoint(event.canvasPosition)) {
        onPlayAgain();
      } else if (exitText.containsPoint(event.canvasPosition)) {
        onExit();
      }
    }
  }
}

class Ball extends CircleComponent {
  final int number;
  final BallType type;
  Vector2 velocity = Vector2.zero();

  Ball(this.number, Vector2 position, this.type, double radius)
      : super(
          radius: radius,
          position: position,
          paint: Paint()..color = _getBallColor(number, type),
        );

  static Color _getBallColor(int number, BallType type) {
    if (type == BallType.cue) return Colors.white;
    if (type == BallType.eight) return Colors.black;

    List<Color> colors = [
      Colors.yellow,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.cyanAccent,
    ];

    return colors[number % colors.length];
  }

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.99; // Slight friction
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (type == BallType.striped) {
      final stripePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset.zero, radius * 0.7, stripePaint);
    }

    final textPainter = TextPaint(
      style: TextStyle(
        color: type == BallType.cue || type == BallType.striped
            ? Colors.black
            : Colors.white,
        fontSize: radius,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.render(
        canvas, number.toString(), Vector2(-radius / 2, -radius / 2));
  }
}

class PocketComponent extends CircleComponent {
  PocketComponent({required Vector2 position, required double radius})
      : super(
          radius: radius,
          position: position,
          paint: Paint()..color = Colors.black,
        );
}

class ShootingLine extends PositionComponent {
  final Paint _paint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2;

  Vector2 _start = Vector2.zero();
  Vector2 _end = Vector2.zero();
  bool _visible = false;

  void updateLine(Vector2 start, Vector2 end) {
    _start = start;
    _end = end;
  }

  void setVisible(bool visible) {
    _visible = visible;
  }

  @override
  void render(Canvas canvas) {
    if (_visible) {
      canvas.drawLine(_start.toOffset(), _end.toOffset(), _paint);
    }
  }
}
