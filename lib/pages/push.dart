import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class KnockoutGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasGameRef {
  static const playerRadius = 20.0;
  static const arenaSize = 500.0;
  static const arenaPadding = 100.0;

  late Player userPlayer;
  late List<Player> botPlayers;
  late ShootingLine shootingLine;

  Vector2 dragStart = Vector2.zero();
  Vector2 dragEnd = Vector2.zero();

  bool gameOver = false;
  bool playerWon = false;
  int score = 0;

  late TextComponent scoreText;
  late TextComponent gameOverText;
  late TextComponent playAgainText;
  late TextComponent exitText;

  final Function() onPlayAgain;
  final Function() onExit;

  KnockoutGame({required this.onPlayAgain, required this.onExit});

  @override
  Future<void> onLoad() async {
    add(ArenaComponent());

    userPlayer = Player(0, Vector2(size.x / 2, size.y / 2), isBot: false);
    botPlayers = [
      Player(1, Vector2(arenaPadding, arenaPadding), isBot: true),
      Player(2, Vector2(size.x - arenaPadding, arenaPadding), isBot: true),
      Player(3, Vector2(arenaPadding, size.y - arenaPadding), isBot: true),
    ];

    add(userPlayer);
    botPlayers.forEach(add);

    shootingLine = ShootingLine();
    add(shootingLine);

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
    add(scoreText);

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

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameOver) {
      [userPlayer, ...botPlayers].forEach((player) => player.update(dt));
      checkCollisions(dt);
      checkKnockouts();
      updateBots(dt);
      scoreText.text = 'Score: $score';
    }
  }

  void checkCollisions(double dt) {
    List<Player> allPlayers = [userPlayer, ...botPlayers];
    for (var player in allPlayers) {
      for (var otherPlayer in allPlayers) {
        if (player != otherPlayer) {
          final Vector2 normal = otherPlayer.position - player.position;
          final double distance = normal.length;
          if (distance <= playerRadius * 2) {
            normal.normalize();

            final Vector2 relativeVelocity =
                otherPlayer.velocity - player.velocity;
            final double velocityAlongNormal = relativeVelocity.dot(normal);

            if (velocityAlongNormal > 0) continue;

            final double restitution = 0.9;
            final double impulseScalar =
                -(1 + restitution) * velocityAlongNormal / 2;

            final Vector2 impulse = normal * impulseScalar;
            player.velocity -= impulse;
            otherPlayer.velocity += impulse;

            final double separation = (playerRadius * 2 - distance) / 2;
            player.position -= normal * separation;
            otherPlayer.position += normal * separation;
          }
        }
      }
    }
  }

  void checkKnockouts() {
    botPlayers.removeWhere((player) => isPlayerKnockedOut(player));
    score = 3 - botPlayers.length;

    if (isPlayerKnockedOut(userPlayer)) {
      gameOver = true;
      playerWon = false;
      showGameOver();
    }

    if (botPlayers.isEmpty) {
      gameOver = true;
      playerWon = true;
      showGameOver();
    }
  }

  bool isPlayerKnockedOut(Player player) {
    return player.position.x < arenaPadding - playerRadius ||
        player.position.x > size.x - arenaPadding + playerRadius ||
        player.position.y < arenaPadding - playerRadius ||
        player.position.y > size.y - arenaPadding + playerRadius;
  }

  void updateBots(double dt) {
    for (var bot in botPlayers) {
      if (bot.velocity.length < 10) {
        List<Player> targets = [...botPlayers, userPlayer]..remove(bot);
        Player target = targets[Random().nextInt(targets.length)];
        Vector2 direction = target.position - bot.position;
        direction.normalize();
        bot.velocity = direction * 200;
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (!gameOver && userPlayer.containsPoint(event.canvasPosition)) {
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
      shootingLine.updateLine(
          userPlayer.position, userPlayer.position + direction);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!gameOver && dragStart != Vector2.zero()) {
      final direction = dragStart - dragEnd;
      final strength = direction.length.clamp(0.0, 300.0);
      userPlayer.velocity = direction.normalized() * strength * 0.8;
      dragStart = Vector2.zero();
      dragEnd = Vector2.zero();
      shootingLine.setVisible(false);
    }
  }

  void showGameOver() {
    gameOverText.text = playerWon ? 'You Won!' : 'Game Over';
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
    playerWon = false;
    score = 0;

    userPlayer.position = Vector2(size.x / 2, size.y / 2);
    userPlayer.velocity = Vector2.zero();

    botPlayers.clear();
    botPlayers = [
      Player(1, Vector2(arenaPadding, arenaPadding), isBot: true),
      Player(2, Vector2(size.x - arenaPadding, arenaPadding), isBot: true),
      Player(3, Vector2(arenaPadding, size.y - arenaPadding), isBot: true),
    ];
    botPlayers.forEach(add);
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

class Player extends CircleComponent {
  final int number;
  Vector2 velocity = Vector2.zero();
  final bool isBot;

  Player(this.number, Vector2 position, {required this.isBot})
      : super(
          radius: KnockoutGame.playerRadius,
          position: position,
          paint: Paint()..color = isBot ? Colors.red : Colors.blue,
        );

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.98;
  }
}

class ArenaComponent extends PositionComponent with HasGameRef<KnockoutGame> {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(
          KnockoutGame.arenaPadding,
          KnockoutGame.arenaPadding,
          gameRef.size.x - 2 * KnockoutGame.arenaPadding,
          gameRef.size.y - 2 * KnockoutGame.arenaPadding),
      Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
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
    Vector2 direction = end - start;
    _end = start + direction.normalized() * 100;
  }

  void setVisible(bool visible) {
    _visible = visible;
  }

  @override
  void render(Canvas canvas) {
    if (_visible) {
      canvas.drawLine(_start.toOffset(), _end.toOffset(), _paint);
      final arrowhead = Path()
        ..moveTo(_end.x, _end.y)
        ..lineTo(_end.x - 10, _end.y + 5)
        ..lineTo(_end.x - 10, _end.y - 5)
        ..close();
      canvas.drawPath(arrowhead, _paint);
    }
  }
}
