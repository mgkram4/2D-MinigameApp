import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, String>> gameData = [
    {
      'title': 'Memory Game',
      'description': 'Test your memory skills.',
      'route': '/memory-game',
    },
    {
      'title': 'Whack-a-Mole',
      'description': 'Hit the moles as fast as you can!',
      'route': '/whack-a-mole',
    },
    {
      'title': 'Tic-Tac-Toe',
      'description': 'Classic Tic-Tac-Toe game.',
      'route': '/tic-tac-toe',
    },
    {
      'title': 'Pool Game',
      'description': 'Pocket the balls and score points!',
      'route': '/pool-game',
    },
    {
      'title': 'Golf Game',
      'description': 'Pocket the balls and score points!',
      'route': '/golf-game',
    },
    {
      'title': 'Dart Game',
      'description': 'Throw darts and aim for the bullseye!',
      'route': '/dart-game',
    },
    {
      'title': 'Basketball',
      'description': 'Shoot hoops and score baskets!',
      'route': '/basketball-game',
    },
    {
      'title': 'Sumo Game',
      'description': 'Push other players out of the ring!',
      'route': '/sumo-game',
    },
    {
      'title': 'Shooter Game',
      'description': 'Push other players out of the ring!',
      'route': '/space-shooter',
    },
  ];

  DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildGamesSection(context),
              ),
              _buildShopSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'HOME',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'GAMES',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: gameData.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, gameData[index]['route']!);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.games, size: 48, color: Colors.white70),
                        SizedBox(height: 8),
                        Text(
                          gameData[index]['title']!,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHOP (COMING SOON)',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.shopping_bag, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
