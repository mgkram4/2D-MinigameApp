import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GolfGame extends FlameGame with DragCallbacks, TapCallbacks, HasGameRef {
  static const ballRadius = 10.0;
  static const holeRadius = 15.0;
  static const coursePadding = 20.0;
  static const obstacleSize = 40.0;
  static const maxDragDistance = 300.0;
  late double courseWidth;
  late double courseHeight;

  late Ball golfBall;
  Hole? currentHole;
  List<SquareObstacle> obstacles = [];

  Vector2 dragStart = Vector2.zero();
  Vector2 dragEnd = Vector2.zero();

  int score = 0;
  late Timer gameTimer;
  bool gameOver = false;

  late ShootingLine shootingLine;
  late TextComponent scoreComponent;
  late TextComponent timerComponent;

  late TextComponent gameOverText;
  late TextComponent playAgainText;
  late TextComponent exitText;

  final Function() onPlayAgain;
  final Function() onExit;

  GolfGame({required this.onPlayAgain, required this.onExit}) {
    golfBall = Ball(Vector2.zero());
  }

  @override
  Future<void> onLoad() async {
    courseWidth = size.x - 2 * coursePadding;
    courseHeight = size.y - 2 * coursePadding;

    add(CourseComponent());
    resetBall();
    generateNewHole();
    if (currentHole != null) {
      add(currentHole!);
    }

    shootingLine = ShootingLine();
    add(shootingLine);

    gameTimer = Timer(60, onTick: () {
      gameOver = true;
    });

    scoreComponent = TextComponent(
      position: Vector2(coursePadding + 10, 40),
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(scoreComponent);

    timerComponent = TextComponent(
      position: Vector2(size.x - 100, 40),
      text: 'Time: 60',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(timerComponent);

    gameOverText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2 - 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 40),
      ),
    );

    playAgainText = TextComponent(
      text: 'Play Again',
      position: Vector2(size.x / 2, size.y / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
    );

    exitText = TextComponent(
      text: 'Exit',
      position: Vector2(size.x / 2, size.y / 2 + 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
    );

    hideGameOverComponents();
  }

  void resetBall() {
    golfBall.position = Vector2(
      courseWidth / 2 + coursePadding,
      courseHeight * 3 / 4 + coursePadding,
    );
    golfBall.velocity = Vector2.zero();
    add(golfBall);
  }

  void generateNewHole() {
    obstacles.forEach((obstacle) => remove(obstacle));
    obstacles.clear();

    final random = Random();

    Vector2 holePosition;
    do {
      holePosition = Vector2(
        random.nextDouble() * (courseWidth - 2 * holeRadius) +
            coursePadding +
            holeRadius,
        random.nextDouble() * (courseHeight - 2 * holeRadius) +
            coursePadding +
            holeRadius,
      );
    } while (holePosition.distanceTo(golfBall.position) < 100);

    if (currentHole != null) remove(currentHole!);
    currentHole = Hole(holePosition);
    add(currentHole!);

    generateObstacles(random);
  }

  void generateObstacles(Random random) {
    int numObstacles = random.nextInt(5) + 5; // 5 to 9 obstacles

    for (int i = 0; i < numObstacles; i++) {
      Vector2 obstaclePosition;
      bool validPosition;
      do {
        obstaclePosition = Vector2(
          random.nextDouble() * (courseWidth - obstacleSize) + coursePadding,
          random.nextDouble() * (courseHeight - obstacleSize) + coursePadding,
        );
        validPosition = true;

        // Check distance from hole and ball
        if (obstaclePosition.distanceTo(currentHole!.position) <
                obstacleSize * 2 ||
            obstaclePosition.distanceTo(golfBall.position) < obstacleSize * 2) {
          validPosition = false;
          continue;
        }

        // Check overlap with other obstacles
        for (var obstacle in obstacles) {
          if (obstaclePosition.distanceTo(obstacle.position) <
              obstacleSize * 1.5) {
            validPosition = false;
            break;
          }
        }
      } while (!validPosition);

      final obstacle = SquareObstacle(obstaclePosition);
      obstacles.add(obstacle);
      add(obstacle);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameOver) {
      golfBall.update(dt);
      checkCollisions();
      checkHole();
      gameTimer.update(dt);

      scoreComponent.text = 'Score: $score';
      timerComponent.text = 'Time: ${max(0, (60 - gameTimer.current).floor())}';

      if (gameTimer.finished) {
        gameOver = true;
        showGameOver();
      }
    }
  }

  void checkCollisions() {
    checkCourseBoundaries();
    checkObstacleCollisions();
  }

  void checkCourseBoundaries() {
    if (golfBall.position.x - ballRadius < coursePadding) {
      golfBall.position.x = coursePadding + ballRadius;
      golfBall.velocity.x = -golfBall.velocity.x * 0.8;
    } else if (golfBall.position.x + ballRadius > size.x - coursePadding) {
      golfBall.position.x = size.x - coursePadding - ballRadius;
      golfBall.velocity.x = -golfBall.velocity.x * 0.8;
    }
    if (golfBall.position.y - ballRadius < coursePadding) {
      golfBall.position.y = coursePadding + ballRadius;
      golfBall.velocity.y = -golfBall.velocity.y * 0.8;
    } else if (golfBall.position.y + ballRadius > size.y - coursePadding) {
      golfBall.position.y = size.y - coursePadding - ballRadius;
      golfBall.velocity.y = -golfBall.velocity.y * 0.8;
    }
  }

  void checkObstacleCollisions() {
    for (var obstacle in obstacles) {
      final Rect obstacleRect = Rect.fromLTWH(
        obstacle.position.x,
        obstacle.position.y,
        obstacleSize,
        obstacleSize,
      );

      final Vector2 closestPoint = Vector2(
        golfBall.position.x.clamp(obstacleRect.left, obstacleRect.right),
        golfBall.position.y.clamp(obstacleRect.top, obstacleRect.bottom),
      );

      final Vector2 difference = golfBall.position - closestPoint;
      final double distance = difference.length;

      if (distance < ballRadius) {
        // Collision detected
        final Vector2 normal = difference.normalized();

        // Move the ball out of the obstacle
        final double overlap = ballRadius - distance;
        golfBall.position += normal * overlap;

        // Calculate the reflection
        final double dotProduct = golfBall.velocity.dot(normal);
        final Vector2 reflection =
            golfBall.velocity - (normal * 2 * dotProduct);

        // Apply the reflection with some energy loss and add a small random factor
        final double energyLoss = 0.8;
        final double randomFactor =
            1 + (Random().nextDouble() - 0.5) * 0.2; // ±10% randomness
        golfBall.velocity = reflection * energyLoss * randomFactor;

        // Add a small perpendicular force to reduce "stuck" scenarios
        final Vector2 perpendicular = Vector2(-normal.y, normal.x);
        final double perpendicularForce = golfBall.velocity.length * 0.1;
        golfBall.velocity +=
            perpendicular * perpendicularForce * (Random().nextBool() ? 1 : -1);

        // Ensure the ball isn't moving too slowly after collision
        final double minSpeed = 20.0;
        if (golfBall.velocity.length < minSpeed) {
          golfBall.velocity = golfBall.velocity.normalized() * minSpeed;
        }
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (!gameOver && golfBall.containsPoint(event.canvasPosition)) {
      dragStart = event.canvasPosition;
      dragEnd = dragStart;
      shootingLine.setVisible(true);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!gameOver && dragStart != Vector2.zero()) {
      dragEnd = event.canvasPosition;
      final direction = dragStart - dragEnd;
      shootingLine.updateLine(golfBall.position, golfBall.position + direction);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!gameOver && dragStart != Vector2.zero()) {
      final direction = dragStart - dragEnd;
      final strength = direction.length.clamp(0.0, maxDragDistance);
      golfBall.velocity = direction.normalized() * strength * 2;
      dragStart = Vector2.zero();
      dragEnd = Vector2.zero();
      shootingLine.setVisible(false);
    }
  }

  void checkHole() {
    if (currentHole != null &&
        golfBall.position.distanceTo(currentHole!.position) < holeRadius) {
      score++;
      resetBall();
      generateNewHole();
    }
  }

  void showGameOver() {
    gameOverText.text = 'Game Over';
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
    score = 0;
    gameTimer.reset();

    resetBall();
    generateNewHole();
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
  Vector2 velocity = Vector2.zero();

  Ball(Vector2 position)
      : super(
          radius: GolfGame.ballRadius,
          position: position,
          paint: Paint()..color = Colors.white,
        );

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.99; // Apply some air resistance

    // Stop the ball if it's moving very slowly
    if (velocity.length < 5) {
      velocity = Vector2.zero();
    }
  }
}

class Hole extends CircleComponent {
  Hole(Vector2 position)
      : super(
          radius: GolfGame.holeRadius,
          position: position,
          paint: Paint()..color = Colors.black,
        );
}

class SquareObstacle extends RectangleComponent {
  SquareObstacle(Vector2 position)
      : super(
          position: position,
          size: Vector2.all(GolfGame.obstacleSize),
          paint: Paint()..color = Colors.brown,
        );
}

class CourseComponent extends PositionComponent with HasGameRef<GolfGame> {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = Colors.green[800]!,
    );

    canvas.drawRect(
      Rect.fromLTWH(GolfGame.coursePadding, GolfGame.coursePadding,
          gameRef.courseWidth, gameRef.courseHeight),
      Paint()..color = Colors.green[600]!,
    );
  }
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
