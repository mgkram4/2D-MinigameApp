import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:game_1/pages/dashboard.dart';

class BasketballGame extends FlameGame with TapCallbacks, DragCallbacks {
  static const ballRadius = 15.0;
  static const hoopWidth = 80.0;
  static const hoopHeight = 40.0;
  static const courtPadding = 20.0;
  static const maxShootPower = 1000.0;

  late double courtWidth;
  late double courtHeight;

  late Ball basketball;
  late Hoop hoop;

  Vector2 dragStart = Vector2.zero();
  Vector2 currentDragPosition = Vector2.zero();

  int score = 0;
  int attempts = 0;
  late Timer gameTimer;
  bool gameOver = false;

  late TextComponent scoreComponent;
  late TextComponent timerComponent;
  late TextComponent gameOverText;
  late TextComponent playAgainText;
  late TextComponent exitText;

  final Function() onPlayAgain;
  final Function() onExit;

  BasketballGame({required this.onPlayAgain, required this.onExit});

  @override
  Future<void> onLoad() async {
    courtWidth = size.x - 2 * courtPadding;
    courtHeight = size.y - 2 * courtPadding;

    add(Background());
    add(CourtComponent());

    hoop = Hoop(Vector2(size.x / 2, size.y / 4));
    add(hoop);

    basketball = Ball(Vector2(size.x / 2, size.y * 0.8));
    add(basketball);

    gameTimer = Timer(60, onTick: () {
      gameOver = true;
      showGameOver();
    });

    scoreComponent = TextComponent(
      position: Vector2(courtPadding + 10, 40),
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    add(scoreComponent);

    timerComponent = TextComponent(
      position: Vector2(size.x - 100, 40),
      text: 'Time: 60',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
    add(timerComponent);

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
      basketball.update(dt);
      checkScore();
      gameTimer.update(dt);

      scoreComponent.text = 'Score: $score / $attempts';
      timerComponent.text = 'Time: ${max(0, (60 - gameTimer.current).floor())}';

      if (basketball.position.y > size.y + ballRadius) {
        resetBall();
      }
    }
  }

  void resetBall() {
    basketball.position = Vector2(size.x / 2, size.y * 0.8);
    basketball.velocity = Vector2.zero();
    basketball.isMoving = false;
  }

  void checkScore() {
    if (basketball.isMoving &&
        basketball.position.y < hoop.position.y + hoopHeight / 2 &&
        basketball.position.y > hoop.position.y - hoopHeight / 2 &&
        basketball.position.x > hoop.position.x - hoopWidth / 2 &&
        basketball.position.x < hoop.position.x + hoopWidth / 2 &&
        basketball.velocity.y > 0) {
      score++;
      addScoreEffect();
      resetBall();
    }
  }

  void addScoreEffect() {
    final random = Random();
    add(
      ParticleSystemComponent(
        position: hoop.position,
        particle: Particle.generate(
          count: 20,
          lifespan: 1,
          generator: (i) => AcceleratedParticle(
            speed: Vector2(
              random.nextDouble() * 100 - 50,
              random.nextDouble() * -100 - 50,
            ),
            acceleration: Vector2(0, 98),
            child: CircleParticle(
              radius: 2,
              paint: Paint()..color = Colors.yellow,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (!gameOver && !basketball.isMoving) {
      dragStart = event.canvasPosition;
      currentDragPosition = dragStart;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!gameOver && dragStart != Vector2.zero()) {
      currentDragPosition = event.canvasPosition;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!gameOver && dragStart != Vector2.zero()) {
      final dragVector = currentDragPosition - dragStart;
      final shootPower = dragVector.length.clamp(0.0, maxShootPower);

      if (dragVector.y < 0 && dragVector.y.abs() > dragVector.x.abs()) {
        basketball.velocity = dragVector.normalized() * shootPower * 1.5;
        basketball.isMoving = true;
        attempts++;
        addTrajectoryEffect(dragVector);
      }

      dragStart = Vector2.zero();
      currentDragPosition = Vector2.zero();
    }
  }

  void addTrajectoryEffect(Vector2 dragVector) {
    final particleCount = 10;
    final particleLifespan = 0.5;
    for (var i = 0; i < particleCount; i++) {
      final progress = i / (particleCount - 1);
      add(
        ParticleSystemComponent(
          position: basketball.position,
          particle: Particle.generate(
            count: 1,
            lifespan: particleLifespan,
            generator: (i) => MovingParticle(
              from: basketball.position + dragVector * progress,
              to: basketball.position +
                  dragVector * (progress + 1 / (particleCount - 1)),
              child: CircleParticle(
                radius: 2,
                paint: Paint()..color = Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      );
    }
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
    attempts = 0;
    gameTimer.reset();
    resetBall();
  }
}

class Ball extends CircleComponent {
  Vector2 velocity = Vector2.zero();
  bool isMoving = false;

  Ball(Vector2 position)
      : super(
          radius: BasketballGame.ballRadius,
          position: position,
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final ballPaint = Paint()..color = Colors.orange;
    canvas.drawCircle(Offset.zero, BasketballGame.ballRadius, ballPaint);

    // Draw seams
    final seamPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: BasketballGame.ballRadius),
      0,
      pi,
      false,
      seamPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: BasketballGame.ballRadius),
      pi / 2,
      pi,
      false,
      seamPaint,
    );
  }

  void update(double dt) {
    if (isMoving) {
      position += velocity * dt;
      velocity += Vector2(0, 500) * dt; // Apply gravity
      velocity *= 0.99; // Apply air resistance
    }
  }
}

class Hoop extends PositionComponent {
  static const backboardWidth = 5.0;
  static const backboardHeight = 40.0;

  Hoop(Vector2 position)
      : super(
          position: position,
          size: Vector2(BasketballGame.hoopWidth, BasketballGame.hoopHeight),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    // Draw rim
    final rimPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 0), width: size.x, height: size.y / 2),
      rimPaint,
    );

    // Draw net
    final netPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 12; i++) {
      final angle = i * (pi / 6);
      final startX = cos(angle) * size.x / 2;
      final startY = sin(angle) * size.y / 4;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX * 0.7, size.y / 2 + 20),
        netPaint,
      );
    }
  }
}

class CourtComponent extends PositionComponent with HasGameRef<BasketballGame> {
  @override
  void render(Canvas canvas) {
    // Draw court
    canvas.drawRect(
      Rect.fromLTWH(BasketballGame.courtPadding, BasketballGame.courtPadding,
          gameRef.courtWidth, gameRef.courtHeight),
      Paint()..color = Color(0xFFCD853F),
    );

    // Draw court lines
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Three-point line
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(gameRef.size.x / 2, gameRef.size.y),
        width: gameRef.courtWidth * 0.8,
        height: gameRef.courtWidth * 0.8 + 200,
      ),
      pi,
      pi,
      false,
      linePaint,
    );

    // Free throw line
    canvas.drawLine(
      Offset(gameRef.size.x / 2 - 60, gameRef.size.y - 150),
      Offset(gameRef.size.x / 2 + 60, gameRef.size.y - 150),
      linePaint,
    );

    // Key
    canvas.drawRect(
      Rect.fromLTWH(
        gameRef.size.x / 2 - 60,
        gameRef.size.y - 190,
        120,
        190,
      ),
      linePaint,
    );
  }
}

class Background extends PositionComponent with HasGameRef<BasketballGame> {
  @override
  void render(Canvas canvas) {
    // Fill the background with black
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = Colors.black,
    );
  }
}

class BasketballGameWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GameWidget<BasketballGame>(
      game: BasketballGame(
        onPlayAgain: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BasketballGameWidget()),
          );
        },
        onExit: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        },
      ),
    );
  }
}
