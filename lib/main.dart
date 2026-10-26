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
      title: 'Aethelgard: Siege of Kings',
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
  int gold = 1500;
  int gems = 50;
  int castleHp = 100;
  int maxCastleHp = 100;
  int arrowDamage = 25;
  int wave = 1;
  int score = 0;

  void addGold(int amount) => setState(() => gold += amount);
  void addGems(int amount) => setState(() => gems += amount);
  void damageCastle(int amount) {
    setState(() {
      castleHp -= amount;
      if (castleHp <= 0) {
        castleHp = maxCastleHp;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Castle Breached! Wave Restarted.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      BattleArenaView(
        gold: gold,
        gems: gems,
        castleHp: castleHp,
        maxCastleHp: maxCastleHp,
        arrowDamage: arrowDamage,
        wave: wave,
        onReward: (g, s) {
          addGold(g);
          setState(() => score += s);
        },
        onDamageCastle: damageCastle,
      ),
      UpgradesView(
        gold: gold,
        arrowDamage: arrowDamage,
        maxCastleHp: maxCastleHp,
        onUpgradeDamage: (cost) {
          setState(() {
            gold -= cost;
            arrowDamage += 15;
          });
        },
        onUpgradeWall: (cost) {
          setState(() {
            gold -= cost;
            maxCastleHp += 50;
            castleHp = maxCastleHp;
          });
        },
      ),
      const CampaignMapView(),
      TavernSummonView(gems: gems, onSummon: () {
        if (gems >= 50) {
          setState(() => gems -= 50);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚔️ Epic Paladin Hero Summoned!')),
          );
        }
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatChip(Icons.monetization_on, "$gold", Colors.amber),
            _buildStatChip(Icons.diamond, "$gems", Colors.cyan),
            _buildStatChip(Icons.shield, "HP: $castleHp/$maxCastleHp", Colors.greenAccent),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: screens[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.security), label: "Battle"),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "Upgrades"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Campaign"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Heroes"),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------- 1. BATTLE ARENA VIEW (ACTION GAMEPLAY) ----------------
class Enemy {
  double x; // 0.0 (Castle) to 1.0 (Spawn right)
  int hp;
  int maxHp;
  double speed;
  String name;
  Color color;

  Enemy({required this.x, required this.hp, required this.maxHp, required this.speed, required this.name, required this.color});
}

class BattleArenaView extends StatefulWidget {
  final int gold;
  final int gems;
  final int castleHp;
  final int maxCastleHp;
  final int arrowDamage;
  final int wave;
  final Function(int, int) onReward;
  final Function(int) onDamageCastle;

  const BattleArenaView({
    super.key,
    required this.gold,
    required this.gems,
    required this.castleHp,
    required this.maxCastleHp,
    required this.arrowDamage,
    required this.wave,
    required this.onReward,
    required this.onDamageCastle,
  });

  @override
  State<BattleArenaView> createState() => _BattleArenaViewState();
}

class _BattleArenaViewState extends State<BattleArenaView> with SingleTickerProviderStateMixin {
  late Timer _gameLoop;
  final List<Enemy> _enemies = [];
  final Random _rand = Random();
  int enemiesDefeated = 0;

  @override
  void initState() {
    super.initState();
    // Game Loop at ~30 FPS
    _gameLoop = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      _updateGame();
    });
    // Spawn initial enemies
    _spawnEnemy();
    _spawnEnemy();
  }

  @override
  void dispose() {
    _gameLoop.cancel();
    super.dispose();
  }

  void _spawnEnemy() {
    if (_enemies.length < 5) {
      bool isOrc = _rand.nextBool();
      setState(() {
        _enemies.add(Enemy(
          x: 1.0,
          hp: isOrc ? 60 : 30,
          maxHp: isOrc ? 60 : 30,
          speed: isOrc ? 0.003 : 0.005,
          name: isOrc ? "Orc Raider" : "Goblin Thief",
          color: isOrc ? Colors.redAccent : Colors.orangeAccent,
        ));
      });
    }
  }

  void _updateGame() {
    setState(() {
      for (int i = _enemies.length - 1; i >= 0; i--) {
        _enemies[i].x -= _enemies[i].speed;
        // Reach Castle
        if (_enemies[i].x <= 0.05) {
          widget.onDamageCastle(10);
          _enemies.removeAt(i);
          _spawnEnemy();
        }
      }
      if (_enemies.length < 4 && _rand.nextInt(50) == 1) {
        _spawnEnemy();
      }
    });
  }

  void _tapAttackEnemy(Enemy enemy) {
    setState(() {
      enemy.hp -= widget.arrowDamage;
      if (enemy.hp <= 0) {
        _enemies.remove(enemy);
        enemiesDefeated++;
        widget.onReward(50, 10);
        _spawnEnemy();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Wave ${widget.wave} - Tap Enemies to Shoot!", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text("Defeated: $enemiesDefeated", style: const TextStyle(color: Colors.cyan)),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width = constraints.maxWidth;
                double height = constraints.maxHeight;

                return Stack(
                  children: [
                    // Battlefield background lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BattlefieldPainter(),
                      ),
                    ),
                    // Castle Wall on Left
                    Positioned(
                      left: 10,
                      top: height / 2 - 80,
                      child: Container(
                        width: 60,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          border: Border.all(color: Colors.amber, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fort, color: Colors.amber, size: 36),
                            SizedBox(height: 4),
                            Text("WALL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // Enemies marching from right to left
                    ..._enemies.map((enemy) {
                      double posX = 80 + (width - 150) * enemy.x;
                      return Positioned(
                        left: posX,
                        top: height / 2 - 30 + (_rand.nextDouble() * 100 - 50),
                        child: GestureDetector(
                          onTap: () => _tapAttackEnemy(enemy),
                          child: Column(
                            children: [
                              Container(
                                width: 36,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (enemy.hp / enemy.maxHp).clamp(0.0, 1.0),
                                  child: Container(decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(3))),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: enemy.color,
                                  shape: BoxShape.circle,
                                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.android, size: 24, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(enemy.name, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("👆 Tap rapidly on marching enemy units to fire archer arrows!", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class BattlefieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height / 2 + 50), Offset(size.width, size.height / 2 + 50), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------- 2. UPGRADES VIEW ----------------
class UpgradesView extends StatelessWidget {
  final int gold;
  final int arrowDamage;
  final int maxCastleHp;
  final Function(int) onUpgradeDamage;
  final Function(int) onUpgradeWall;

  const UpgradesView({
    super.key,
    required this.gold,
    required this.arrowDamage,
    required this.maxCastleHp,
    required this.onUpgradeDamage,
    required this.onUpgradeWall,
  });

  @override
  Widget build(BuildContext context) {
    int dmgCost = 200;
    int wallCost = 300;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          const Text("🛡️ Kingdom Armory & Upgrades", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const Icon(Icons.bolt, color: Colors.amber, size: 36),
              title: const Text("Archer Arrow Damage", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Current Damage: $arrowDamage"),
              trailing: ElevatedButton(
                onPressed: gold >= dmgCost ? () => onUpgradeDamage(dmgCost) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text("$dmgCost Gold", style: const TextStyle(color: Colors.black)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E293B),
            child: ListTile(
              leading: const Icon(Icons.shield, color: Colors.greenAccent, size: 36),
              title: const Text("Castle Wall Durability", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Max Wall HP: $maxCastleHp"),
              trailing: ElevatedButton(
                onPressed: gold >= wallCost ? () => onUpgradeWall(wallCost) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                child: Text("$wallCost Gold", style: const TextStyle(color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. CAMPAIGN MAP VIEW ----------------
class CampaignMapView extends StatelessWidget {
  const CampaignMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: 6,
      itemBuilder: (context, index) {
        bool unlocked = index < 3;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: unlocked ? Colors.amber : Colors.grey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(unlocked ? Icons.lock_open : Icons.lock, size: 40, color: unlocked ? Colors.amber : Colors.grey),
              const SizedBox(height: 8),
              Text("Province ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(unlocked ? "Ready to Raid" : "Locked", style: TextStyle(fontSize: 12, color: unlocked ? Colors.green : Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- 4. HERO TAVERN VIEW ----------------
class TavernSummonView extends StatelessWidget {
  final int gems;
  final VoidCallback onSummon;

  const TavernSummonView({super.key, required this.gems, required this.onSummon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.cyan),
            const SizedBox(height: 16),
            const Text("Hero Summon Portal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyan)),
            const SizedBox(height: 8),
            const Text("Summon legendary commanders to defend Aethelgard!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: gems >= 50 ? onSummon : null,
              icon: const Icon(Icons.star, color: Colors.black),
              label: const Text("Summon Hero (50 Gems)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
