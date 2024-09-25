// import 'dart:async';
// import 'dart:ui';

// import 'package:flame/components.dart';
// import 'package:flame/game.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:game_center/main.dart';
// import 'package:flutter/material.dart';

// class PoolGame extends FlameGame{
//   PoolGame({super.children});
//   @override
//   Color backgroundColor() => Color.fromARGB(255, 81, 166, 55);
//   @override
//   FutureOr<void> onLoad() async{
//     final poolTable = PoolTable();
//     add(poolTable);
//   }
// }
// class PoolTable extends SpriteComponent{
//   @override
//   FutureOr<void> onLoad() async{
//     sprite = await Sprite.load("pool_table.jpg");
//     size = Vector2(550, 350);
//     position = Vector2(200, 400);
//     anchor = Anchor.center;
//     angle = 1.5708;
//   }
// }
// class PoolGamePage extends StatelessWidget{
//   Widget build(BuildContext context){
//   return Scaffold(
//     body: Container(
//       color: Colors.black,
//       child: Column(
//         children: [
//           header(context),
//       ],
//     )
//   )
//   );
// }
// Widget header(BuildContext context){
//   return Container(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pushNamed(context, '/');
//             },
//             child: Icon(Icons.home),
//           ) 
//         ],
//       )
//     );
//   }
// }



// import 'dart:math';

// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flutter/material.dart';

// class PoolGame extends FlameGame with DragCallbacks {
//   static const ballRadius = 10.0;
//   static const pocketRadius = 20.0;
//   static const tablePadding = 10.5; // Reduced to 3/4 of the original 50.0
//   late double tableWidth;
//   late double tableHeight;

//   late Ball cueBall;
//   List<Ball> balls = [];
//   List<Vector2> pockets = [];

//   Vector2 dragStart = Vector2.zero();
//   Vector2 dragEnd = Vector2.zero();

//   int score = 0;

//   late ShootingLine shootingLine;

//   @override
//   Future<void> onLoad() async {
//     tableWidth = size.x - 2 * tablePadding;
//     tableHeight = size.y - 2 * tablePadding;

//     add(TableComponent());
//     setupPockets();
//     resetBalls();
//     balls.forEach(add);
//     add(cueBall);
//     pockets.forEach((pocket) => add(PocketComponent(position: pocket)));

//     shootingLine = ShootingLine();
//     add(shootingLine);

//     add(
//       TextComponent(
//         position: Vector2(tablePadding + 10, tablePadding + 10),
//         text: 'Score: 0',
//         textRenderer: TextPaint(
//           style: const TextStyle(color: Colors.white, fontSize: 20),
//         ),
//       ),
//     );
//   }

//   void setupPockets() {
//     double padding = pocketRadius + tablePadding;
//     pockets = [
//       Vector2(padding, padding),
//       Vector2(tableWidth / 2 + tablePadding, padding),
//       Vector2(tableWidth + tablePadding - pocketRadius, padding),
//       Vector2(padding, tableHeight + tablePadding - pocketRadius),
//       Vector2(tableWidth / 2 + tablePadding,
//           tableHeight + tablePadding - pocketRadius),
//       Vector2(tableWidth + tablePadding - pocketRadius,
//           tableHeight + tablePadding - pocketRadius),
//     ];
//   }

//   void resetBalls() {
//     balls.clear();
//     double startX = tableWidth / 2 + tablePadding;
//     double startY = tableHeight / 3 + tablePadding;
//     double rowSpacing = ballRadius * 2 * sin(pi / 3);
//     double colSpacing = ballRadius * 2;

//     List<List<int>> rackPattern = [
//       [11, 12, 13, 14, 15],
//       [7, 8, 9, 10],
//       [4, 5, 6],
//       [2, 3],
//       [1]
//     ];

//     for (int row = 0; row < rackPattern.length; row++) {
//       for (int col = 0; col < rackPattern[row].length; col++) {
//         int ballNumber = rackPattern[row][col];
//         double x =
//             startX + (col - rackPattern[row].length / 2 + 0.5) * colSpacing;
//         double y = startY + row * rowSpacing;
//         balls.add(Ball(ballNumber, Vector2(x, y)));
//       }
//     }

//     cueBall = Ball(
//         0,
//         Vector2(
//             tableWidth / 2 + tablePadding, tableHeight * 3 / 4 + tablePadding));
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     balls.forEach((ball) => ball.update(dt));
//     cueBall.update(dt);
//     checkCollisions();
//     checkPockets();

//     final scoreComponent = children.whereType<TextComponent>().first;
//     scoreComponent.text = 'Score: $score';
//   }

//   void checkCollisions() {
//     for (var ball in [cueBall, ...balls]) {
//       if (ball.position.x - ballRadius < tablePadding ||
//           ball.position.x + ballRadius > tableWidth + tablePadding) {
//         ball.velocity.x *= -0.9;
//       }
//       if (ball.position.y - ballRadius < tablePadding ||
//           ball.position.y + ballRadius > tableHeight + tablePadding) {
//         ball.velocity.y *= -0.9;
//       }

//       for (var otherBall in [cueBall, ...balls]) {
//         if (ball != otherBall) {
//           final distance = ball.position.distanceTo(otherBall.position);
//           if (distance <= ballRadius * 2) {
//             final normal = (otherBall.position - ball.position).normalized();
//             final relativeVelocity = ball.velocity - otherBall.velocity;
//             final velocityAlongNormal = relativeVelocity.dot(normal);

//             final restitution =
//                 0.1; // Reduced from 0.8 to make collisions less strong
//             final impulseScalar = -(1 + restitution) * velocityAlongNormal / 2;

//             final impulse = normal *
//                 impulseScalar *
//                 0.5; // Added a factor of 0.3 to further reduce collision strength
//             ball.velocity -= impulse;
//             otherBall.velocity += impulse;

//             // Separate balls to prevent sticking
//             final overlap = ballRadius * 2 - distance;
//             final separationVector = normal * (overlap / 2);
//             ball.position -= separationVector;
//             otherBall.position += separationVector;
//           }
//         }
//       }
//     }
//   }

//   void checkPockets() {
//     for (var pocket in pockets) {
//       for (var ball in [...balls, cueBall]) {
//         if (ball.position.distanceTo(pocket) < pocketRadius) {
//           if (ball != cueBall) {
//             balls.remove(ball);
//             remove(ball);
//             score++;
//           } else {
//             cueBall.position.setFrom(Vector2(tableWidth / 2 + tablePadding,
//                 tableHeight * 3 / 4 + tablePadding));
//             cueBall.velocity.setZero();
//           }
//         }
//       }
//     }
//   }

//   @override
//   void onDragStart(DragStartEvent event) {
//     if (cueBall.containsPoint(event.canvasPosition)) {
//       dragStart = event.canvasPosition;
//       dragEnd = dragStart;
//       shootingLine.setVisible(true);
//     }
//   }

//   @override
//   void onDragUpdate(DragUpdateEvent event) {
//     if (dragStart != Vector2.zero()) {
//       dragEnd = event.canvasPosition;
//       final direction = dragStart - dragEnd;
//       shootingLine.updateLine(cueBall.position, cueBall.position + direction);
//     }
//   }

//   @override
//   void onDragEnd(DragEndEvent event) {
//     if (dragStart != Vector2.zero()) {
//       final direction = dragStart - dragEnd;
//       final strength = direction.length.clamp(0.0, 300.0);
//       cueBall.velocity = direction.normalized() * strength * 2;
//       dragStart = Vector2.zero();
//       dragEnd = Vector2.zero();
//       shootingLine.setVisible(false);
//     }
//   }
// }

// class Ball extends CircleComponent {
//   final int number;
//   Vector2 velocity = Vector2.zero();

//   Ball(this.number, Vector2 position)
//       : super(
//           radius: PoolGame.ballRadius,
//           position: position,
//           paint: Paint()
//             ..color = number == 0
//                 ? Colors.white
//                 : Colors.primaries[number % Colors.primaries.length],
//         );

//   void update(double dt) {
//     position += velocity * dt;
//     velocity *= 0.98;
//   }
// }

// class PoolTable extends SpriteComponent{
//   @override
//   FutureOr<void> onLoad() async{
//     sprite = await Sprite.load("pool_table.jpg");
//     size = Vector2(550, 350);
//     position = Vector2(200, 400);
//     anchor = Anchor.center;
//     angle = 1.5708;
//   }
// }

// class TableComponent extends PositionComponent with HasGameRef<PoolGame> {
//   @override
//   void render(Canvas canvas) {
//     canvas.drawRect(
//       Rect.fromLTWH(PoolGame.tablePadding, PoolGame.tablePadding,
//           gameRef.tableWidth, gameRef.tableHeight),
//       Paint()..color = Colors.green[800]!,
//     );
//   }
// }

// class CombinedTableComponent extends SpriteComponent with HasGameRef<PoolGame> {
//   CombinedTableComponent() : super(anchor: Anchor.center);

//   @override
//   FutureOr<void> onLoad() async {
//     // Load the sprite
//     sprite = await Sprite.load("pool_table.jpg");
//     size = Vector2(550, 350);
//     position = Vector2(200, 400);
//     angle = 1.5708;

//     // Set size based on the game reference if needed
//     size = Vector2(gameRef.tableWidth, gameRef.tableHeight);
//   }

//   @override
//   void render(Canvas canvas) {
//     // Draw the table background as a green rectangle
//     canvas.drawRect(
//       Rect.fromLTWH(
//         PoolGame.tablePadding,
//         PoolGame.tablePadding,
//         gameRef.tableWidth,
//         gameRef.tableHeight,
//       ),
//       Paint()..color = Colors.green[800]!,
//     );

//     // Draw the sprite
//     super.render(canvas);
//   }
// }

// class PocketComponent extends CircleComponent {
//   PocketComponent({required Vector2 position})
//       : super(
//           radius: PoolGame.pocketRadius,
//           position: position,
//           paint: Paint()..color = Colors.black,
//         );
// }

// class ShootingLine extends PositionComponent {
//   final Paint _paint = Paint()
//     ..color = Colors.white
//     ..strokeWidth = 2;

//   Vector2 _start = Vector2.zero();
//   Vector2 _end = Vector2.zero();
//   bool _visible = false;

//   void updateLine(Vector2 start, Vector2 end) {
//     _start = start;
//     _end = end;
//   }

//   void setVisible(bool visible) {
//     _visible = visible;
//   }

//   @override
//   void render(Canvas canvas) {
//     if (_visible) {
//       canvas.drawLine(_start.toOffset(), _end.toOffset(), _paint);
//     }
//   }
// }
