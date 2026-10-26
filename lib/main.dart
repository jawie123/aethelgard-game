import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const AethelgardApp());
}

class AethelgardApp extends StatelessWidget {
  const AethelgardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aethelgard: Kings & Conundrums',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFFD97706),
      ),
      home: const MainGameScreen(),
    );
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  int _currentIndex = 0;
  int gold = 25000;
  int gems = 850;
  int keepLevel = 1;
  int armyPower = 1200;

  void addResources(int addedGold, int addedGems) {
    setState(() {
      gold += addedGold;
      gems += addedGems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatChip(Icons.monetization_on, "$gold", Colors.amber),
            _buildStatChip(Icons.diamond, "$gems", Colors.cyan),
            _buildStatChip(Icons.flash_on, "Power: $armyPower", Colors.redAccent),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              CityView(
                keepLevel: keepLevel,
                gold: gold,
                onUpgrade: () {
                  if (gold >= keepLevel * 5000) {
                    setState(() {
                      gold -= keepLevel * 5000;
                      keepLevel++;
                      armyPower += 800;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🏰 Keep Upgraded to Level $keepLevel!')),
                    );
                  }
                },
              ),
              PuzzleView(
                onWin: () {
                  addResources(3000, 50);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 Puzzle Solved! +3000 Gold, +50 Gems')),
                  );
                },
              ),
              const WorldMapView(),
              TavernView(
                gems: gems,
                onSummon: () {
                  if (gems >= 100) {
                    setState(() {
                      gems -= 100;
                      armyPower += 500;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚔️ Legendary General Summoned! +500 Power')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fort), label: "City"),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: "Puzzle"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "World Map"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Generals"),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ---------------- 1. CITY VIEW ----------------
class CityView extends StatelessWidget {
  final int keepLevel;
  final int gold;
  final VoidCallback onUpgrade;

  const CityView({super.key, required this.keepLevel, required this.gold, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    int cost = keepLevel * 5000;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fort, size: 100, color: Color(0xFFD97706)),
              const SizedBox(height: 12),
              Text('Aethelgard Keep - Level $keepLevel',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 8),
              const Text('Expand your kingdom and train armies', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: gold >= cost ? onUpgrade : null,
                icon: const Icon(Icons.upgrade),
                label: Text('Upgrade Keep ($cost Gold)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 2. INTERACTIVE PIN PUZZLE VIEW ----------------
class PuzzleView extends StatefulWidget {
  final VoidCallback onWin;
  const PuzzleView({super.key, required this.onWin});

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> {
  bool pin1Pulled = false;
  bool pin2Pulled = false;
  bool lavaDropped = false;
  bool solved = false;
  bool failed = false;

  void pullPin(int pinNumber) {
    if (solved || failed) return;
    setState(() {
      if (pinNumber == 1) {
        pin1Pulled = true;
        lavaDropped = true;
        failed = true;
      } else if (pinNumber == 2) {
        pin2Pulled = true;
        solved = true;
        widget.onWin();
      }
    });
  }

  void resetPuzzle() {
    setState(() {
      pin1Pulled = false;
      pin2Pulled = false;
      lavaDropped = false;
      solved = false;
      failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF020617),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text("🧩 Pin-Pull Physics Challenge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 6),
          const Text("Pull the correct pin to drop treasure safely on the King!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 360,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 3),
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 70,
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      width: 60,
                      height: lavaDropped ? 220 : 40,
                      color: Colors.deepOrange,
                      child: const Center(child: Text("🌋 Lava", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 70,
                    child: Container(
                      width: 60,
                      height: 40,
                      color: Colors.amber,
                      child: const Center(child: Text("💎 Gold", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black))),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    child: Column(
                      children: [
                        Icon(failed ? Icons.sentiment_very_dissatisfied : Icons.person_pin,
                            size: 60, color: failed ? Colors.red : (solved ? Colors.green : Colors.blue)),
                        Text(failed ? "BURNED!" : (solved ? "VICTORY!" : "King"),
                            style: TextStyle(fontWeight: FontWeight.bold, color: failed ? Colors.red : Colors.white)),
                      ],
                    ),
                  ),
                  if (!pin1Pulled)
                    Positioned(
                      top: 100,
                      left: 50,
                      child: GestureDetector(
                        onTap: () => pullPin(1),
                        child: Container(
                          width: 90,
                          height: 14,
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text("Pull Pin 1", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  if (!pin2Pulled)
                    Positioned(
                      top: 100,
                      right: 50,
                      child: GestureDetector(
                        onTap: () => pullPin(2),
                        child: Container(
                          width: 90,
                          height: 14,
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text("Pull Pin 2", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: resetPuzzle,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Puzzle"),
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- 3. WORLD MAP VIEW ----------------
class WorldMapView extends StatelessWidget {
  const WorldMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          bool isKeep = index == 4;
          bool isBoss = index == 2 || index == 9;
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isKeep ? Colors.amber : (isBoss ? Colors.redAccent : Colors.grey)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isKeep ? Icons.fort : (isBoss ? Icons.dangerous : Icons.landscape),
                  size: 32,
                  color: isKeep ? Colors.amber : (isBoss ? Colors.redAccent : Colors.green),
                ),
                const SizedBox(height: 6),
                Text(
                  isKeep ? "Your City" : (isBoss ? "Lvl 15 Boss" : "Resource Node"),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- 4. GENERALS TAVERN VIEW ----------------
class TavernView extends StatelessWidget {
  final int gems;
  final VoidCallback onSummon;

  const TavernView({super.key, required this.gems, required this.onSummon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 80, color: Colors.cyan),
            const SizedBox(height: 16),
            const Text("Generals Tavern Gacha", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 8),
            const Text("Recruit historical military leaders to boost your army power!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: gems >= 100 ? onSummon : null,
              icon: const Icon(Icons.star, color: Colors.black),
              label: const Text("Summon General (100 Gems)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
