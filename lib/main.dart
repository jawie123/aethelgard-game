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
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFFF59E0B),
      ),
      home: const PuzzleGameScreen(),
    );
  }
}

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGameScreen> {
  int currentLevel = 1;
  int gold = 1000;
  int gems = 50;

  // Level State flags
  bool pin1Pulled = false; // Controls Lava
  bool pin2Pulled = false; // Controls Gold / Treasure
  bool pin3Pulled = false; // Controls Goblin Monster
  bool levelCleared = false;
  bool levelFailed = false;

  void resetLevel() {
    setState(() {
      pin1Pulled = false;
      pin2Pulled = false;
      pin3Pulled = false;
      levelCleared = false;
      levelFailed = false;
    });
  }

  void pullPin(int pinNo) {
    if (levelCleared || levelFailed) return;
    setState(() {
      if (pinNo == 1) {
        pin1Pulled = true;
        // Pulling lava pin without blocking goblin first = FAIL
        if (!pin3Pulled) {
          levelFailed = true;
        }
      } else if (pinNo == 2) {
        pin2Pulled = true;
        // Pulling gold pin correctly after clearing obstacles = WIN
        if (pin3Pulled) {
          levelCleared = true;
          gold += 500;
          gems += 20;
        } else {
          levelFailed = true; // Lava burns gold/hero
        }
      } else if (pinNo == 3) {
        pin3Pulled = true; // Blocks or releases goblin/trap
      }
    });
  }

  void nextLevel() {
    setState(() {
      currentLevel++;
      resetLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Level $currentLevel: Rescue Quest", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text("$gold", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                const Icon(Icons.diamond, color: Colors.cyan, size: 18),
                const SizedBox(width: 4),
                Text("$gems", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "🧩 Pull pins in the correct order to save the King and grab the royal treasure!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Game Puzzle Box Arena
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      border: Border.all(color: Colors.amber.withOpacity(0.6), width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Chamber Structure
                        // Lava Chamber Top-Left
                        Positioned(
                          top: 30,
                          left: 40,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 80,
                            height: pin1Pulled ? 180 : 50,
                            decoration: BoxDecoration(
                              color: pin1Pulled ? Colors.deepOrange : Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                pin1Pulled ? "🌋 LAVA FLOW!" : "🌋 Lava Chamber",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        // Treasure Gold Chamber Top-Right
                        Positioned(
                          top: 30,
                          right: 40,
                          child: Container(
                            width: 80,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "💎 Treasury",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ),
                        ),

                        // Goblin Monster Middle
                        Positioned(
                          top: 150,
                          right: 100,
                          child: Opacity(
                            opacity: pin3Pulled ? 0.3 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("👹 Goblin Guard", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),

                        // King / Hero at Bottom
                        Positioned(
                          bottom: 30,
                          child: Column(
                            children: [
                              Icon(
                                levelCleared
                                    ? Icons.sentiment_very_satisfied
                                    : (levelFailed ? Icons.sentiment_very_dissatisfied : Icons.person_pin),
                                size: 54,
                                color: levelCleared ? Colors.greenAccent : (levelFailed ? Colors.redAccent : Colors.blueAccent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                levelCleared ? "VICTORY! REWARD CLAIMED!" : (levelFailed ? "OUCH! TRAPPED!" : "King Aethelgard"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: levelCleared ? Colors.greenAccent : (levelFailed ? Colors.redAccent : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pin 1 (Lava Barrier Pin)
                        if (!pin1Pulled)
                          Positioned(
                            top: 95,
                            left: 30,
                            child: GestureDetector(
                              onTap: () => pullPin(1),
                              child: Container(
                                width: 100,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
                                ),
                                child: const Center(
                                  child: Text("Pull Pin 1 (Lava)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),

                        // Pin 2 (Treasury Barrier Pin)
                        if (!pin2Pulled)
                          Positioned(
                            top: 95,
                            right: 30,
                            child: GestureDetector(
                              onTap: () => pullPin(2),
                              child: Container(
                                width: 100,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
                                ),
                                child: const Center(
                                  child: Text("Pull Pin 2 (Gold)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              ),
                            ),
                          ),

                        // Pin 3 (Goblin Trap Pin)
                        if (!pin3Pulled)
                          Positioned(
                            top: 210,
                            right: 80,
                            child: GestureDetector(
                              onTap: () => pullPin(3),
                              child: Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)],
                                ),
                                child: const Center(
                                  child: Text("Pull Pin 3 (Trap Door)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),

                        // Win / Fail Overlay dialog banners inside arena
                        if (levelCleared)
                          Container(
                            color: Colors.black87,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.military_tech, size: 70, color: Colors.amber),
                                const SizedBox(height: 10),
                                const Text("STAGE CLEARED!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                                const SizedBox(height: 6),
                                const Text("+500 Gold | +20 Gems Earned", style: TextStyle(color: Colors.greenAccent)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  onPressed: nextLevel,
                                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                                  label: const Text("Next Level", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),

                        if (levelFailed)
                          Container(
                            color: Colors.black87,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning, size: 70, color: Colors.redAccent),
                                const SizedBox(height: 10),
                                const Text("LEVEL FAILED!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                const SizedBox(height: 6),
                                const Text("The King was caught in the trap!", style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: resetLevel,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: resetLevel,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset Puzzle"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    ),
                    ElevatedButton.icon(
                      onPressed: levelCleared ? nextLevel : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Next Stage"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
