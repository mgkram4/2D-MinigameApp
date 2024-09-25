import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class DartsGame extends FlameGame with DragCallbacks {
  static const dartRadius = 5.0;
  static const boardRadius = 200.0;
  static const maxShootPower = 800.0;
  static const dartFlightDuration = 2.0;

  late Dart dart;
  late DartBoard dartBoard;
  late AimingLine aimingLine;

  Vector2 dragStart = Vector2.zero();
  Vector2 currentDragPosition = Vector2.zero();

  int score = 0;
  int throws = 0;
  late Timer gameTimer;
  late Timer dartFlightTimer;
  bool gameOver = false;

  late TextComponent scoreComponent;
  late TextComponent timerComponent;
  late TextComponent debugComponent;

  @override
  Future<void> onLoad() async {
    add(Background());

    dartBoard = DartBoard(Vector2(size.x / 2 + 150, size.y / 2));
    add(dartBoard);

    dart = Dart(Vector2(size.x / 2, size.y * 0.8));
    add(dart);

    aimingLine = AimingLine();
    add(aimingLine);

    gameTimer = Timer(90, onTick: () {
      gameOver = true;
    });

    dartFlightTimer = Timer(dartFlightDuration, onTick: () {
      if (dart.isMoving) {
        dart.isMoving = false;
        checkScore();
      }
    });

    scoreComponent = TextComponent(
      position: Vector2(20, 40),
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
      text: 'Time: 90',
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

    debugComponent = TextComponent(
      position: Vector2(20, size.y - 40),
      text: 'Debug: ',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
    add(debugComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameOver) {
      dart.update(dt);
      gameTimer.update(dt);
      if (dart.isMoving) {
        dartFlightTimer.update(dt);
      }

      scoreComponent.text = 'Score: $score';
      timerComponent.text = 'Time: ${max(0, (90 - gameTimer.current).floor())}';

      if (dart.position.y < 0 ||
          dart.position.y > size.y ||
          dart.position.x < 0 ||
          dart.position.x > size.x) {
        checkScore();
      }

      aimingLine.updateLine(dart.position, currentDragPosition);
    }
  }

  void resetDart() {
    dart.position = Vector2(size.x / 2, size.y * 0.8);
    dart.velocity = Vector2.zero();
    dart.isMoving = false;
    dartFlightTimer.reset();
  }

  void checkScore() {
    int points = calculateScore(dart.position);
    score += points;
    addScoreEffect(points);
    throws++;
    resetDart();
  }

  int calculateScore(Vector2 hitPosition) {
    final distance = (hitPosition - dartBoard.position).length;
    final angle =
        (hitPosition - dartBoard.position).angleToSigned(Vector2(1, 0));
    final sector = ((angle + pi) / (pi / 10)).floor() % 20;

    String debugInfo =
        'Hit: (${hitPosition.x.toStringAsFixed(2)}, ${hitPosition.y.toStringAsFixed(2)}), '
        'Distance: ${distance.toStringAsFixed(2)}, '
        'Angle: ${angle.toStringAsFixed(2)}, '
        'Sector: $sector';

    if (distance > boardRadius * 1.1) {
      debugComponent.text = 'Debug: Miss. $debugInfo';
      return 0; // Miss, with a slight buffer
    }

    if (isInBullseye(distance)) {
      debugComponent.text = 'Debug: Bullseye! $debugInfo';
      return 50;
    }
    if (isInOuterBull(distance)) {
      debugComponent.text = 'Debug: Outer Bull. $debugInfo';
      return 25;
    }
    if (isInTriple(distance)) {
      debugComponent.text = 'Debug: Triple. $debugInfo';
      return getTripleScore(sector);
    }
    if (isInDouble(distance)) {
      debugComponent.text = 'Debug: Double. $debugInfo';
      return getDoubleScore(sector);
    }

    debugComponent.text = 'Debug: Single. $debugInfo';
    return getSingleScore(sector);
  }

  bool isInBullseye(double distance) => distance < boardRadius * 0.08;
  bool isInOuterBull(double distance) =>
      distance < boardRadius * 0.20 && !isInBullseye(distance);
  bool isInTriple(double distance) =>
      distance > boardRadius * 0.35 && distance < boardRadius * 0.50;
  bool isInDouble(double distance) =>
      distance > boardRadius * 0.90 && distance <= boardRadius * 1.1;

  int getSingleScore(int sector) {
    const scores = [
      20,
      1,
      18,
      4,
      13,
      6,
      10,
      15,
      2,
      17,
      3,
      19,
      7,
      16,
      8,
      11,
      14,
      9,
      12,
      5
    ];
    return scores[sector];
  }

  int getDoubleScore(int sector) => getSingleScore(sector) * 2;
  int getTripleScore(int sector) => getSingleScore(sector) * 3;

  void addScoreEffect(int points) {
    TextComponent scoreEffect = TextComponent(
      position: dart.position,
      text: points > 0 ? '+$points' : 'Miss',
      textRenderer: TextPaint(
        style: TextStyle(
          color: points > 0 ? Colors.yellow : Colors.red,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    scoreEffect.add(
      MoveEffect.by(
        Vector2(0, -50),
        EffectController(duration: 0.5),
      )..onComplete = () {
          remove(scoreEffect);
        },
    );

    add(scoreEffect);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!gameOver && !dart.isMoving) {
      dragStart = event.canvasPosition;
      currentDragPosition = dragStart;
      aimingLine.visible = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!gameOver && dragStart != Vector2.zero()) {
      currentDragPosition = event.canvasPosition;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!gameOver && dragStart != Vector2.zero() && !dart.isMoving) {
      final dragVector = currentDragPosition - dragStart;
      final shootPower = dragVector.length.clamp(0.0, maxShootPower);

      dart.velocity = dragVector.normalized() * shootPower;
      dart.isMoving = true;
      dartFlightTimer.reset();
      addTrajectoryEffect(dragVector);

      dragStart = Vector2.zero();
      currentDragPosition = Vector2.zero();
      aimingLine.visible = false;
    }
  }

  void addTrajectoryEffect(Vector2 dragVector) {
    final particleCount = 10;
    final particleLifespan = 0.5;
    for (var i = 0; i < particleCount; i++) {
      final progress = i / (particleCount - 1);
      add(
        ParticleSystemComponent(
          position: dart.position,
          particle: Particle.generate(
            count: 1,
            lifespan: particleLifespan,
            generator: (i) => MovingParticle(
              from: dart.position + dragVector * progress,
              to: dart.position +
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
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    dragStart = Vector2.zero();
    currentDragPosition = Vector2.zero();
    aimingLine.visible = false;
  }
}

class Dart extends CircleComponent {
  Vector2 velocity = Vector2.zero();
  bool isMoving = false;

  Dart(Vector2 position)
      : super(
          radius: DartsGame.dartRadius,
          position: position,
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final dartPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset.zero, DartsGame.dartRadius, dartPaint);

    // Draw dart fins
    final finPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(-DartsGame.dartRadius, 0)
        ..lineTo(-DartsGame.dartRadius * 3, -DartsGame.dartRadius)
        ..lineTo(-DartsGame.dartRadius * 3, DartsGame.dartRadius)
        ..close(),
      finPaint,
    );
  }

  void update(double dt) {
    if (isMoving) {
      position += velocity * dt;
      velocity *= 0.99; // Apply air resistance
    }
  }
}

class DartBoard extends CircleComponent {
  DartBoard(Vector2 position)
      : super(
          radius: DartsGame.boardRadius,
          position: position,
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.blue,
      Colors.white
    ];
    final radiusSteps = [1.0, 0.8, 0.6, 0.4, 0.2];

    for (int i = 0; i < radiusSteps.length; i++) {
      final paint = Paint()..color = colors[i];
      canvas.drawCircle(
          Offset.zero, DartsGame.boardRadius * radiusSteps[i], paint);
    }

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var radius in radiusSteps) {
      canvas.drawCircle(
          Offset.zero, DartsGame.boardRadius * radius, circlePaint);
    }
  }
}

class Background extends PositionComponent with HasGameRef<DartsGame> {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = Colors.black,
    );
  }
}

class AimingLine extends Component with HasPaint {
  late Path _path;
  bool visible = false;

  AimingLine() : super() {
    _path = Path();
    paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
  }

  void updateLine(Vector2 start, Vector2 end) {
    _path = Path()
      ..moveTo(start.x, start.y)
      ..lineTo(end.x, end.y);
  }

  @override
  void render(Canvas canvas) {
    if (visible) {
      canvas.drawPath(_path, paint);
    }
  }
}

void main() {
  runApp(
    GameWidget(
      game: DartsGame(),
    ),
  );
}
