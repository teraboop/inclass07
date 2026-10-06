import 'package:flutter/material.dart';

import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _hunger = 50;
  int _happiness = 50;
  int _energy = 50;
  bool _gameOver = false;
  bool _hasWon = false;
  String _petName = 'Doodle';
  final TextEditingController _nameController = TextEditingController();

  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  void _confirmName() {
    final value = _nameController.text.trim();
    if (value.isEmpty) return;
    setState(() => _petName = value);
  }

  void _feedPet() {
    if (_gameOver || _hasWon) return;

    final nextHunger = _clampMeter(_hunger - 10);
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
    });
    _updateOutcome();
  }

  // Running: costs 20 energy and makes the pet hungrier (+10 hunger).
  // Boosts happiness (+15) normally, but if that leaves the pet starving
  // (hunger > 80), exercising on an empty stomach makes it miserable
  // instead (-10). Requires at least 20 energy, otherwise the pet is too
  // tired to run.
  void _runPet() {
    if (_gameOver || _hasWon) return;
    if (_energy < 20) return;

    final nextEnergy = _clampMeter(_energy - 20);
    final nextHunger = _clampMeter(_hunger + 10);
    final happinessChange = nextHunger > 80 ? -10 : 15;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _energy = nextEnergy;
      _hunger = nextHunger;
      _happiness = nextHappiness;
    });
    _updateOutcome();
  }

  // Sleeping: the main way to recover energy (+40), at the cost of getting
  // hungrier (+10 hunger) since the pet isn't eating while asleep.
  void _sleepPet() {
    if (_gameOver || _hasWon) return;

    final nextEnergy = _clampMeter(_energy + 40);
    final nextHunger = _clampMeter(_hunger + 10);

    setState(() {
      _energy = nextEnergy;
      _hunger = nextHunger;
    });
    _updateOutcome();
  }

  Timer? _hungerTimer;
  Timer? _highMoodTimer;

  void _updateOutcome() {
    if (_gameOver || _hasWon) return;

    if (_hunger == 100 && _happiness <= 10) {
      _highMoodTimer?.cancel();
      _hungerTimer?.cancel();
      setState(() => _gameOver = true);
      return;
    }

    if (_happiness <= 80) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    _highMoodTimer ??= Timer(const Duration(minutes: 3), () {
      _highMoodTimer = null;
      if (!mounted || _gameOver || _happiness <= 80) return;
      setState(() => _hasWon = true);
      _hungerTimer?.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = _petName;
    _startHungerTimer();
  }

  // Hunger +5 every 30s (the "Time" rule) plus passive energy drain.
  // Extracted so reset can guarantee exactly one active hunger timer.
  void _startHungerTimer() {
    _hungerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || _gameOver || _hasWon) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_hunger + 5 > 100) {
          _hunger = 100;
          _happiness = _clampMeter(_happiness - 20);
        } else {
          _hunger += 5;
        }
        // Passive energy drain over time; sleeping is the main way back up.
        _energy = _clampMeter(_energy - 3);
      });
      _updateOutcome();
    });
  }

  // Restores initial meters/outcome flags, cancels any running win timer,
  // and restarts exactly one hunger timer.
  void _resetGame() {
    _highMoodTimer?.cancel();
    _highMoodTimer = null;
    _hungerTimer?.cancel();
    setState(() {
      _hunger = 50;
      _happiness = 50;
      _energy = 50;
      _gameOver = false;
      _hasWon = false;
    });
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  String get _petMessage {
    if (_gameOver) return 'I need a rest.';
    if (_hasWon) return 'Best day ever!';
    if (_hunger > 80) return "I'm starving!";
    if (_happiness <= 30) return 'Play with me?';
    if (_energy < 20) return 'So sleepy...';
    return "Hi, I'm $_petName!";
  }

  double get _petScale => _happiness > 70
      ? 1.06
      : _happiness < 30
      ? 0.94
      : 1.0;

  Color get _moodColor {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  // Mirrors _moodColor so mood is never conveyed by color alone.
  IconData get _moodIcon {
    if (_happiness > 70) return Icons.sentiment_very_satisfied;
    if (_happiness >= 30) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  String get _moodLabel {
    if (_happiness > 70) return 'Happy';
    if (_happiness >= 30) return 'Okay';
    return 'Upset';
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final careDisabled = _gameOver || _hasWon;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Pet name',
                        ),
                        onSubmitted: (_) => _confirmName(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Confirm name',
                      onPressed: _confirmName,
                    ),
                  ],
                ),
                AnimatedScale(
                  scale: _petScale,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _moodColor,
                      BlendMode.modulate,
                    ),
                    child: Image.asset('assets/images/pet.png'),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_moodIcon, color: _moodColor),
                    const SizedBox(width: 8),
                    Text(_moodLabel),
                  ],
                ),
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  child: Text(_petMessage, key: ValueKey(_petMessage)),
                ),
                const Text('Hunger'),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _hunger / 100),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    color: Colors.orange,
                  ),
                ),
                const Text('Happiness'),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _happiness / 100),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) =>
                      LinearProgressIndicator(value: value, color: Colors.pink),
                ),
                const Text('Energy'),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _energy / 100),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, _) =>
                      LinearProgressIndicator(value: value, color: Colors.blue),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: careDisabled ? null : _feedPet,
                      child: const Text('Feed'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: careDisabled || _energy < 20 ? null : _runPet,
                      child: const Text('Run'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: careDisabled ? null : _sleepPet,
                      child: const Text('Sleep'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (careDisabled)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hasWon ? 'You win!' : 'Game over',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _resetGame,
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
