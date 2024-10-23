import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'database_helper.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FishTankProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AquariumScreen(),
    );
  }
}

// FishTank Provider
class FishTankProvider extends ChangeNotifier {
  List<Fish> fishList = [];
  double fishSpeed = 1.0;
  Color selectedColor = Colors.blue;

  FishTankProvider() {
    loadFishData();
  }

  Future<void> loadFishData() async {
    var settings = await DatabaseHelper().getAquariumSettings();
    if (settings != null) {
      int fishCount = settings['fish_count'];
      double speed = settings['fish_speed'];
      String colorString = settings['fish_color'];

      // Restore settings
      fishSpeed = speed;
      selectedColor = Color(int.parse(colorString));

      // Restore the number of fish
      fishList = List.generate(fishCount, (index) => Fish(color: selectedColor, speed: fishSpeed));

      notifyListeners();
    }
  }

  // Add fish
  void addFish() {
  if (fishList.length < 10) {
    fishList.add(Fish(color: selectedColor, speed: fishSpeed));
    notifyListeners();
  } else {
    print("Maximum limit of 10 fish reached.");
  }
}

  // Update swimming speed for new fish
  void setSpeed(double speed) {
    fishSpeed = speed;
    notifyListeners();
  }

  // Set color for new fish
  void setColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  // Save current aquarium state
  Future<void> saveAquariumState() async {
    await DatabaseHelper().saveAquariumSettings(
      fishList.length,
      fishSpeed,
      selectedColor.value.toString(), // Save the color as a string
    );
  }
}

// Fish Class
class Fish {
  final Color color;
  final double speed;
  Fish({required this.color, required this.speed});
}

// Aquarium Screen
class AquariumScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          // Set the aquarium size to 300x300 pixels
          SizedBox(
            width: 300,
            height: 300,
            child: Aquarium(),
          ),
          Controls(),
        ],
      ),
    );
  }
}

// Fish Container (Aquarium)
class Aquarium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.3),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Stack(
        children: Provider.of<FishTankProvider>(context)
            .fishList
            .map((fish) => MovingFish(fish: fish))
            .toList(),
      ),
    );
  }
}

class MovingFish extends StatefulWidget {
  final Fish fish;

  MovingFish({required this.fish});

  @override
  _MovingFishState createState() => _MovingFishState();
}

class _MovingFishState extends State<MovingFish> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _x = 150; // Starting x position in pixels (center of 300x300 aquarium)
  double _y = 150; // Starting y position in pixels (center of 300x300 aquarium)
  double _dx = .01; // Horizontal velocity in pixels
  double _dy = .01; // Vertical velocity in pixels

  @override
  void initState() {
    super.initState();
    _randomizeDirection(); // Set random initial velocity
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // Frame rate ~60fps
    )..addListener(_updatePosition)
     ..repeat();
  }

  @override
  void didUpdateWidget(MovingFish oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fish.speed != widget.fish.speed) {
      // Adjust speed based on fish's speed value
      _dx *= widget.fish.speed;
      _dy *= widget.fish.speed;
    }
  }

  void _randomizeDirection() {
    // Generate random velocity components between -2.0 and 2.0 pixels per frame
    final random = Random();
    _dx = (random.nextDouble() * 4.0 - 2.0) * widget.fish.speed;
    _dy = (random.nextDouble() * 4.0 - 2.0) * widget.fish.speed;
  }

  void _updatePosition() {
    setState(() {
      // Update fish position in pixels
      _x += _dx;
      _y += _dy;

      // Detect and handle boundary collisions (bounce)
      if (_x <= 0 || _x >= 300 - 30) { // Account for fish size (30x30)
        _dx = -_dx; // Reverse horizontal direction
      }
      if (_y <= 0 || _y >= 300 - 30) { // Account for fish size (30x30)
        _dy = -_dy; // Reverse vertical direction
      }

      // Keep fish inside bounds
      _x = _x.clamp(0.0, 300.0 - 30.0); // Ensure fish stays within 300x300 area
      _y = _y.clamp(0.0, 300.0 - 30.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,  // Set the x-coordinate
      top: _y,   // Set the y-coordinate
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: widget.fish.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}




// Control Panel (Buttons, Sliders, Dropdowns)
class Controls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FishTankProvider>(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: provider.addFish,
              child: Text('Add Fish'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<FishTankProvider>(context, listen: false).saveAquariumState();
              },
              child: Text("Save"),
            )
          ],
        ),
        Slider(
          value: provider.fishSpeed,
          min: .5,
          max: 3,
          divisions: 5,
          label: 'Speed: ${provider.fishSpeed}',
          onChanged: (value) => provider.setSpeed(value),
        ),
        ColorPicker(),
      ],
    );
  }
}

// Color Picker Dropdown
class ColorPicker extends StatelessWidget {
  final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FishTankProvider>(context);
    return DropdownButton<int>(
      value: provider.selectedColor.value,
      items: colors.map((color) {
        return DropdownMenuItem<int>(
          value: color.value, // Use color value as a unique identifier
          child: Container(
            width: 100,
            height: 20,
            color: color,
          ),
        );
      }).toList(),
      onChanged: (int? value) {
        if (value != null) {
          provider.setColor(Color(value)); // Set color using the selected integer value
        }
      },
    );
  }
}
