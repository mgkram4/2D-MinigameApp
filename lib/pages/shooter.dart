import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class DuckShootingGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  static const birdSize = 50.0;
  static const crosshairSize = 40.0;
  static const cloudSize = 100.0;

  late Player player;
  List<Bird> birds = [];
  List<Cloud> clouds = [];

  int score = 0;
  int highScore = 0;
  int shotsLeft = 6;
  double reloadTime = 0;
  double gameTime = 60; // 60 seconds game time

  late TextComponent scoreComponent;
  late TextComponent shotsComponent;
  late TextComponent timerComponent;
  late TextComponent gameOverText;
  late TextComponent playAgainText;
  late TextComponent exitText;

  final random = Random();

  final Function() onPlayAgain;
  final Function() onExit;

  DuckShootingGame({required this.onPlayAgain, required this.onExit});

  @override
  Future<void> onLoad() async {
    // Add background
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF87CEEB), // Sky blue
    ));

    // Add ground
    add(RectangleComponent(
      size: Vector2(size.x, 50),
      position: Vector2(0, size.y - 50),
      paint: Paint()..color = Colors.green,
    ));

    player = Player();
    add(player);

    scoreComponent = TextComponent(
      position: Vector2(10, 10),
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20, shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
        ]),
      ),
    );
    add(scoreComponent);

    shotsComponent = TextComponent(
      position: Vector2(10, 40),
      text: 'Shots: 6',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20, shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
        ]),
      ),
    );
    add(shotsComponent);

    timerComponent = TextComponent(
      position: Vector2(size.x - 10, 10),
      anchor: Anchor.topRight,
      text: 'Time: 60',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 20, shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
        ]),
      ),
    );
    add(timerComponent);

    gameOverText = TextComponent(
      text: 'Game Over!',
      position: Vector2(size.x / 2, size.y / 2 - 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 40, shadows: [
          Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))
        ]),
      ),
    );

    playAgainText = TextComponent(
      text: 'Play Again',
      position: Vector2(size.x / 2, size.y / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 30, shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
        ]),
      ),
    );

    exitText = TextComponent(
      text: 'Exit',
      position: Vector2(size.x / 2, size.y / 2 + 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 30, shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
        ]),
      ),
    );

    spawnInitialEntities();
  }

  void spawnInitialEntities() {
    // Spawn initial birds
    for (int i = 0; i < 3; i++) {
      spawnBird();
    }

    // Spawn clouds
    for (int i = 0; i < 5; i++) {
      spawnCloud();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameTime > 0) {
      gameTime -= dt;
      timerComponent.text = 'Time: ${gameTime.toInt()}';

      if (random.nextDouble() < 0.02) {
        spawnBird();
      }

      if (random.nextDouble() < 0.01) {
        spawnCloud();
      }

      if (shotsLeft == 0) {
        reloadTime += dt;
        if (reloadTime >= 2) {
          shotsLeft = 6;
          reloadTime = 0;
        }
      }

      clouds.removeWhere((cloud) => cloud.isOffScreen());
      birds.removeWhere((bird) => bird.isOffScreen());

      scoreComponent.text = 'Score: $score';
      shotsComponent.text =
          shotsLeft > 0 ? 'Shots: $shotsLeft' : 'Reloading...';
    } else if (gameTime <= 0 && !contains(gameOverText)) {
      showGameOver();
    }
  }

  void spawnBird() {
    final isFromLeft = random.nextBool();
    final isDove = random.nextDouble() < 0.3; // 30% chance of spawning a dove
    final bird = Bird(
      isDove ? BirdType.dove : BirdType.duck,
      isFromLeft
          ? Vector2(-birdSize, 50 + random.nextDouble() * (size.y - 150))
          : Vector2(
              size.x + birdSize, 50 + random.nextDouble() * (size.y - 150)),
      Vector2((isFromLeft ? 1 : -1) * (100 + random.nextDouble() * 100), 0),
    );
    birds.add(bird);
    add(bird);
  }

  void spawnCloud() {
    final cloud = Cloud(
      Vector2(size.x + cloudSize, random.nextDouble() * (size.y / 2)),
      Vector2(-(20 + random.nextDouble() * 30), 0),
    );
    clouds.add(cloud);
    add(cloud);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameTime <= 0) {
      if (playAgainText.containsPoint(event.canvasPosition)) {
        onPlayAgain();
      } else if (exitText.containsPoint(event.canvasPosition)) {
        onExit();
      }
    } else if (shotsLeft > 0) {
      shotsLeft--;
      player.shoot(event.canvasPosition);

      for (final bird in birds) {
        if (bird.containsPoint(event.canvasPosition)) {
          bird.hit();
          if (bird.type == BirdType.duck) {
            score += 10;
          } else {
            score -= 20; // Penalty for shooting a dove
          }
          add(
            ParticleSystemComponent(
              particle: Particle.generate(
                count: 20,
                lifespan: 0.1,
                generator: (i) => AcceleratedParticle(
                  acceleration: getRandomVector(),
                  speed: getRandomVector(),
                  position: event.canvasPosition.clone(),
                  child: CircleParticle(
                    radius: 2,
                    paint: Paint()
                      ..color = bird.type == BirdType.duck
                          ? Colors.orange
                          : Colors.white,
                  ),
                ),
              ),
            ),
          );
          break;
        }
      }
    }
  }

  void showGameOver() {
    add(gameOverText);
    add(playAgainText);
    add(exitText);

    highScore = score > highScore ? score : highScore;
    gameOverText.text = 'Game Over!\nScore: $score\nHigh Score: $highScore';
  }

  void restartGame() {
    gameTime = 60;
    score = 0;
    shotsLeft = 6;
    reloadTime = 0;
    birds.clear();
    clouds.clear();
    children.whereType<Bird>().forEach((bird) => bird.removeFromParent());
    children.whereType<Cloud>().forEach((cloud) => cloud.removeFromParent());
    gameOverText.removeFromParent();
    playAgainText.removeFromParent();
    exitText.removeFromParent();
    spawnInitialEntities();
  }

  Vector2 getRandomVector() {
    return (Vector2.random() - Vector2.random()) * random.nextDouble() * 500;
  }
}

class Player extends PositionComponent with HasGameRef<DuckShootingGame> {
  Player() : super(size: Vector2.all(DuckShootingGame.crosshairSize));

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.red.withOpacity(0.5),
    );
    canvas.drawLine(
      Offset(0, size.y / 2),
      Offset(size.x, size.y / 2),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(size.x / 2, 0),
      Offset(size.x / 2, size.y),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
  }

  void shoot(Vector2 position) {
    this.position = position;
    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ),
    );
  }
}

enum BirdType { duck, dove }

class Bird extends PositionComponent with HasGameRef<DuckShootingGame> {
  final Vector2 velocity;
  final BirdType type;
  bool isHit = false;
  double flapTime = 0;

  Bird(this.type, Vector2 position, this.velocity)
      : super(
          position: position,
          size: Vector2.all(DuckShootingGame.birdSize),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (!isHit) {
      position += velocity * dt;
      flapTime += dt;
      if (flapTime > 0.2) {
        flapTime = 0;
      }
    } else {
      position.y += 200 * dt;
      angle += 5 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = isHit
          ? Colors.red
          : (type == BirdType.duck ? Colors.brown : Colors.white);
    canvas.drawRect(size.toRect(), paint);

    // Draw wing
    final wingPaint = Paint()
      ..color = type == BirdType.duck ? Colors.white : Colors.grey;
    final wingRect = Rect.fromLTWH(0, size.y / 2, size.x / 2, size.y / 4);
    canvas.drawRect(wingRect, wingPaint);

    // Animate wing
    if (!isHit) {
      canvas.drawRect(
        Rect.fromLTWH(
            0, size.y / 2 + sin(flapTime * 20) * 5, size.x / 2, size.y / 4),
        wingPaint,
      );
    }
  }

  bool isOffScreen() {
    final game = gameRef;
    return position.x < -size.x ||
        position.x > game.size.x + size.x ||
        position.y > game.size.y;
  }

  void hit() {
    isHit = true;
  }
}

class Cloud extends PositionComponent with HasGameRef<DuckShootingGame> {
  final Vector2 velocity;

  Cloud(Vector2 position, this.velocity)
      : super(
          position: position,
          size: Vector2.all(DuckShootingGame.cloudSize),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withOpacity(0.7);
    final path = Path()
      ..moveTo(0, size.y / 2)
      ..quadraticBezierTo(size.x / 4, 0, size.x / 2, size.y / 2)
      ..quadraticBezierTo(3 * size.x / 4, size.y, size.x, size.y / 2)
      ..quadraticBezierTo(3 * size.x / 4, 0, size.x / 2, size.y / 2)
      ..quadraticBezierTo(size.x / 4, size.y, 0, size.y / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  bool isOffScreen() {
    return position.x < -size.x;
  }
}
