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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Gold: $gold", style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Gems: $gems", style: const TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(child: Text("🏰 Isometric City Keep", style: TextStyle(fontSize: 22))),
          Center(child: Text("🧩 Flame Box2D Physics Pin Puzzles", style: TextStyle(fontSize: 22))),
          Center(child: Text("🗺️ World Map & Marching Engine", style: TextStyle(fontSize: 22))),
          Center(child: Text("🛡️ High-Tier Generals Tavern Gacha", style: TextStyle(fontSize: 22))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.location_city), label: "City"),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: "Puzzles"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "World Map"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Generals"),
        ],
      ),
    );
  }
}
