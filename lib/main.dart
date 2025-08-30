import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'workout_scraper.dart';
import 'workout_detail_screen.dart';
import 'weekly_workout_screen.dart';
import 'network_permission_dialog.dart';
import 'home_widgets.dart';

void main() {
  runApp(const FitnessFirstApp());
}

class FitnessFirstApp extends StatelessWidget {
  const FitnessFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness First',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFFA855F7),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF9FAFB),
          onPrimary: Color(0xFFFFFFFF),
          onSecondary: Color(0xFFFFFFFF),
          onSurface: Color(0xFF111827),
          onBackground: Color(0xFF111827),
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
        ),
      ),
      home: const FitnessHomePage(),
    );
  }
}

class Workout {
  final String id;
  final String name;
  final String category;
  final List<String> exercises;
  final int totalSets;
  int completedSets;
  bool isActive;
  Timer? timer;
  int remainingSeconds;
  final LinearGradient gradient;
  final String emoji;
  final int duration; // in minutes

  Workout({
    required this.id,
    required this.name,
    required this.category,
    required this.exercises,
    required this.totalSets,
    this.completedSets = 0,
    this.isActive = false,
    this.remainingSeconds = 0,
    required this.gradient,
    required this.emoji,
    required this.duration,
  });
}

class FitnessHomePage extends StatefulWidget {
  const FitnessHomePage({super.key});

  @override
  State<FitnessHomePage> createState() => _FitnessHomePageState();
}

class _FitnessHomePageState extends State<FitnessHomePage>
    with TickerProviderStateMixin {
  List<Workout> workouts = [];
  List<Workout> savedWorkouts = [];
  int activeWorkouts = 0;
  int totalSets = 0;
  double completionRate = 0.0;
  int _currentIndex = 0;
  int completedWorkouts = 0;
  int totalTimeSpent = 0; // in minutes
  int _selectedTabIndex = 0;
  bool _hasShownNetworkDialog = false;

  @override
  void initState() {
    super.initState();
    _initializeWorkouts();
    _updateStats();
    _checkNetworkPermission();
  }

  void _checkNetworkPermission() async {
    // Show network permission dialog after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && !_hasShownNetworkDialog) {
      _showNetworkPermissionDialog();
    }
  }

  void _showNetworkPermissionDialog() {
    setState(() {
      _hasShownNetworkDialog = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkPermissionDialog(),
    );
  }

  void _initializeWorkouts() {
    workouts = [
      Workout(
        id: '1',
        name: 'Upper Body Blast',
        category: 'Strength',
        exercises: ['Bench Press', 'Pull-ups', 'Shoulder Press', 'Rows', 'Dips', 'Bicep Curls', 'Tricep Extensions', 'Push-ups'],
        totalSets: 8,
        completedSets: 3,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        emoji: '🏋️',
        duration: 45,
      ),
      Workout(
        id: '2',
        name: 'HIIT Cardio',
        category: 'Cardio',
        exercises: ['Burpees', 'Mountain Climbers', 'Jump Squats', 'High Knees', 'Plank Jacks', 'Sprint Intervals'],
        totalSets: 6,
        completedSets: 0,
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        emoji: '🏃',
        duration: 20,
      ),
      Workout(
        id: '3',
        name: 'Core Destroyer',
        category: 'Core',
        exercises: ['Crunches', 'Planks', 'Russian Twists', 'Leg Raises', 'Bicycle Crunches'],
        totalSets: 5,
        completedSets: 5,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        emoji: '🔥',
        duration: 30,
      ),
      Workout(
        id: '4',
        name: 'Leg Day Power',
        category: 'Legs',
        exercises: ['Squats', 'Deadlifts', 'Lunges', 'Leg Press', 'Calf Raises', 'Leg Extensions', 'Leg Curls'],
        totalSets: 7,
        completedSets: 0,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        emoji: '🦵',
        duration: 60,
      ),
    ];
  }

  void _updateStats() {
    setState(() {
      activeWorkouts = workouts.where((w) => w.isActive).length;
      totalSets = workouts.fold(0, (sum, w) => sum + w.completedSets);
      int totalPossibleSets = workouts.fold(0, (sum, w) => sum + w.totalSets);
      completionRate = totalPossibleSets > 0 ? (totalSets / totalPossibleSets) * 100 : 0;
      completedWorkouts = workouts.where((w) => w.completedSets == w.totalSets).length;
      totalTimeSpent = workouts.fold(0, (sum, w) => sum + (w.completedSets * w.duration ~/ w.totalSets));
    });
  }

  void _startWorkout(Workout workout) {
    setState(() {
      workout.isActive = true;
      workout.remainingSeconds = workout.duration * 60; // Convert minutes to seconds
      workout.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (workout.remainingSeconds > 0) {
            workout.remainingSeconds--;
          } else {
            timer.cancel();
            workout.isActive = false;
          }
        });
      });
    });
    _updateStats();
  }

  void _pauseWorkout(Workout workout) {
    setState(() {
      workout.isActive = false;
      workout.timer?.cancel();
    });
    _updateStats();
  }

  void _completeSet(Workout workout) {
    setState(() {
      if (workout.completedSets < workout.totalSets) {
        workout.completedSets++;
      }
    });
    _updateStats();
  }

  void _addWorkoutFromUrl() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddWorkoutBottomSheet(
        onWorkoutAdded: (workout) {
          print('Callback received workout: ${workout.name}');
          setState(() {
            savedWorkouts.add(workout);
            _currentIndex = 1;
            _selectedTabIndex = 1; // Switch to Workouts tab
          });
          _updateStats();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${workout.name} added to saved workouts!'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _openActiveWorkout(Workout workout) {
    final workoutData = {
      'title': workout.name,
      'category': workout.category,
      'exercises': workout.exercises.map((exercise) => {
        'name': exercise,
        'sets': 3,
        'reps': 10,
        'equipment': '',
      }).toList(),
      'totalSets': workout.totalSets,
      'source': 'Active Workout',
    };
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          workoutData: workoutData,
          onWorkoutUpdated: (updatedData) {
            setState(() {
              final index = workouts.indexWhere((w) => w.id == workout.id);
              if (index != -1) {
                final category = updatedData['category'];
                final gradient = _getGradientForCategory(category);
                final emoji = _getEmojiForCategory(category);
                
                final exerciseList = (updatedData['exercises'] as List)
                    .map((e) => e['name'].toString())
                    .toList();
                
                workouts[index] = Workout(
                  id: workout.id,
                  name: updatedData['title'],
                  category: category,
                  exercises: exerciseList,
                  totalSets: updatedData['totalSets'],
                  gradient: gradient,
                  emoji: emoji,
                  duration: workout.duration,
                );
              }
            });
          },
        ),
      ),
    );
  }

  void _openSavedWorkout(Workout workout) {
    final workoutData = {
      'title': workout.name,
      'category': workout.category,
      'exercises': workout.exercises.map((exercise) => {
        'name': exercise,
        'sets': 3,
        'reps': 10,
        'equipment': '',
      }).toList(),
      'totalSets': workout.totalSets,
      'source': 'Saved Workout',
    };
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          workoutData: workoutData,
          onWorkoutUpdated: (updatedData) {
            setState(() {
              final index = savedWorkouts.indexWhere((w) => w.id == workout.id);
              if (index != -1) {
                final category = updatedData['category'];
                final gradient = _getGradientForCategory(category);
                final emoji = _getEmojiForCategory(category);
                
                final exerciseList = (updatedData['exercises'] as List)
                    .map((e) => e['name'].toString())
                    .toList();
                
                savedWorkouts[index] = Workout(
                  id: workout.id,
                  name: updatedData['title'],
                  category: category,
                  exercises: exerciseList,
                  totalSets: updatedData['totalSets'],
                  gradient: gradient,
                  emoji: emoji,
                  duration: workout.duration,
                );
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteSavedWorkout(Workout workout) {
    setState(() {
      savedWorkouts.removeWhere((w) => w.id == workout.id);
    });
    _updateStats();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ ${workout.name} deleted from saved workouts'),
        backgroundColor: const Color(0xFF6B7280),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  LinearGradient _getGradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFDE047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'back':
        return const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'arms':
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'legs':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'shoulders':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'full body':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _getEmojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return '🏋️';
      case 'back':
        return '💪';
      case 'arms':
        return '💪';
      case 'legs':
        return '🦵';
      case 'shoulders':
        return '🏋️';
      case 'full body':
        return '🔥';
      default:
        return '💪';
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App title and settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FitFlow',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Text(
                    'Your personal trainer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF6B7280),
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Greeting card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ready to crush your goals?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.track_changes,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.check_circle,
                        value: completedWorkouts.toString(),
                        label: 'Completed',
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.access_time,
                        value: '${totalTimeSpent}m',
                        label: 'Time Spent',
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.local_fire_department,
                        value: '7',
                        label: 'Day Streak',
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.fitness_center,
                        value: '24',
                        label: 'Total Done',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 800));
  }

  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Active Workouts',
              icon: Icons.fitness_center,
              isSelected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Saved Workouts',
              icon: Icons.bookmark,
              isSelected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildWorkoutsTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildQuickActions(),
          _buildYourWorkouts(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  title: 'Import Workout',
                  subtitle: 'From URL',
                  icon: Icons.link,
                  color: const Color(0xFF10B981),
                  onTap: _addWorkoutFromUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  title: 'Create Custom',
                  subtitle: 'New workout',
                  icon: Icons.add,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    // TODO: Implement custom workout creation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom workout creation coming soon!'),
                        backgroundColor: Color(0xFF6B7280),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourWorkouts() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Workouts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 1;
                  });
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show recent workouts (active + saved)
          if (workouts.isNotEmpty || savedWorkouts.isNotEmpty) ...[
            WorkoutCardNew(
              workout: workouts.isNotEmpty ? workouts.first : savedWorkouts.first,
              onTap: () {
                if (workouts.isNotEmpty && workouts.first == (workouts.isNotEmpty ? workouts.first : savedWorkouts.first)) {
                  _openActiveWorkout(workouts.first);
                } else {
                  _openSavedWorkout(savedWorkouts.first);
                }
              },
            ),
            if ((workouts.length + savedWorkouts.length) > 1) ...[
              const SizedBox(height: 12),
              WorkoutCardNew(
                workout: workouts.length > 1 ? workouts[1] : (savedWorkouts.isNotEmpty ? savedWorkouts.first : workouts.first),
                onTap: () {
                  if (workouts.length > 1) {
                    _openActiveWorkout(workouts[1]);
                  } else if (savedWorkouts.isNotEmpty) {
                    _openSavedWorkout(savedWorkouts.first);
                  } else {
                    _openActiveWorkout(workouts.first);
                  }
                },
              ),
            ],
            if ((workouts.length + savedWorkouts.length) > 2) ...[
              const SizedBox(height: 12),
              WorkoutCardNew(
                workout: workouts.length > 2 ? workouts[2] : (savedWorkouts.length > 1 ? savedWorkouts[1] : (workouts.length > 1 ? workouts[1] : savedWorkouts.first)),
                onTap: () {
                  if (workouts.length > 2) {
                    _openActiveWorkout(workouts[2]);
                  } else if (savedWorkouts.length > 1) {
                    _openSavedWorkout(savedWorkouts[1]);
                  } else if (workouts.length > 1) {
                    _openActiveWorkout(workouts[1]);
                  } else {
                    _openSavedWorkout(savedWorkouts.first);
                  }
                },
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF9CA3AF),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No workouts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Import your first workout to get started!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Workouts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Workouts list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Show active workouts
                ...workouts.map((workout) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkoutCardNew(
                    workout: workout,
                    onTap: () => _openActiveWorkout(workout),
                  ),
                )),
                
                // Show saved workouts
                ...savedWorkouts.map((workout) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkoutCardNew(
                    workout: workout,
                    onTap: () => _openSavedWorkout(workout),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.settings,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Settings screen coming soon!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWorkoutContent() {
    switch (_currentIndex) {
      case 0:
        return _buildActiveWorkoutsTab();
      case 1:
        return _buildSavedWorkoutsTab();
      default:
        return _buildActiveWorkoutsTab();
    }
  }

  Widget _buildActiveWorkoutsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          return _WorkoutCard(
            workout: workouts[index],
            onStart: () => _openActiveWorkout(workouts[index]),
            onPause: () => _pauseWorkout(workouts[index]),
            onCompleteSet: () => _completeSet(workouts[index]),
          );
        },
      ),
    );
  }

  Widget _buildSavedWorkoutsTab() {
    if (savedWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Saved Workouts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a workout from URL to see it here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: savedWorkouts.length,
        itemBuilder: (context, index) {
          return _SavedWorkoutCard(
            workout: savedWorkouts[index],
            onTap: () => _openSavedWorkout(savedWorkouts[index]),
            onDelete: () => _deleteSavedWorkout(savedWorkouts[index]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentTabContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex == 1 ? FloatingActionButton.extended(
        onPressed: _addWorkoutFromUrl,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Workout'),
        elevation: 4,
      ).animate().scale(delay: const Duration(milliseconds: 500)) : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _SavedWorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SavedWorkoutCard({
    required this.workout,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: workout.gradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          workout.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workout.category,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  workout.name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.exercises.length} exercises',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${workout.duration}m',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Tap to Edit',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 * int.parse(workout.id)));
  }
}

class _WorkoutCard extends StatefulWidget {
  final Workout workout;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onCompleteSet;

  const _WorkoutCard({
    required this.workout,
    required this.onStart,
    required this.onPause,
    required this.onCompleteSet,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.workout.totalSets > 0
        ? widget.workout.completedSets / widget.workout.totalSets
        : 0.0;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: widget.workout.gradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                widget.workout.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.workout.category,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        widget.workout.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        widget.workout.exercises.take(2).join(', '),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.workout.completedSets}/${widget.workout.totalSets}',
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.workout.isActive)
                                Text(
                                  '${(widget.workout.remainingSeconds / 60).floor()}:${(widget.workout.remainingSeconds % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                      
                                            const SizedBox(height: 8),
                      
                      Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: widget.onStart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  child: const Icon(Icons.play_arrow, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: widget.onCompleteSet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(40, 40),
                                ),
                                child: const Icon(Icons.check, size: 16),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 * int.parse(widget.workout.id)));
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Scraping Workout...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fetching exercises, sets, and reps from the URL',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWorkoutBottomSheet extends StatefulWidget {
  final Function(Workout) onWorkoutAdded;

  const _AddWorkoutBottomSheet({required this.onWorkoutAdded});

  @override
  State<_AddWorkoutBottomSheet> createState() => _AddWorkoutBottomSheetState();
}

class _AddWorkoutBottomSheetState extends State<_AddWorkoutBottomSheet> {
  late final TextEditingController _urlController;
  bool _isLoading = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: 'https://www.muscleandfitness.com/routine/workouts/workout-routines/chris-hemsworths-god-thor-workout/',
    );
  }

  void _addWorkout() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LoadingDialog(),
      );

      final result = await WorkoutScraper.scrapeWorkout(_urlController.text);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (result['success']) {
        final workoutData = result['data'];
        
        if (mounted) {
          String message = '✅ ${workoutData['title']} scraped successfully!';
          if (result['note'] != null) {
            message += '\n${result['note']}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        if (mounted) {
          // Automatically save the scraped workout
          final category = workoutData['category'];
          final gradient = _getGradientForCategory(category);
          final emoji = _getEmojiForCategory(category);
          
          // Convert weekly workout to a single workout for saving
          final allExercises = workoutData['weeklyWorkout']['allExercises'] as List<Map<String, dynamic>>;
          final exerciseNames = allExercises.map((e) => e['name'].toString()).toList();
          
          final workout = Workout(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: workoutData['title'],
            category: category,
            exercises: exerciseNames,
            totalSets: workoutData['totalSets'],
            gradient: gradient,
            emoji: emoji,
            duration: _calculateTotalDuration(workoutData['weeklyWorkout']),
          );
          
          print('Workout being added: ${workout.name}');
          widget.onWorkoutAdded(workout);
          
          // Show the workout details screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WeeklyWorkoutScreen(
                workoutData: workoutData,
                onWorkoutSaved: (workoutMap) {
                  // Already saved, just show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Workout already saved!'),
                      backgroundColor: Color(0xFF10B981),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['error']}'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  
  int _calculateTotalDuration(Map<String, dynamic> weeklyWorkout) {
    int totalDuration = 0;
    final days = weeklyWorkout.keys.where((key) => key != 'allExercises' && key != 'totalSets' && key != 'totalDays');
    
    for (final day in days) {
      final dayData = weeklyWorkout[day] as Map<String, dynamic>;
      totalDuration += dayData['duration'] as int;
    }
    
    return totalDuration;
  }
  
  LinearGradient _getGradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFDE047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'back':
        return const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'arms':
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'legs':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'shoulders':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'full body':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
  
  String _getEmojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return '🏋️';
      case 'back':
        return '💪';
      case 'arms':
        return '💪';
      case 'legs':
        return '🦵';
      case 'shoulders':
        return '🏋️';
      case 'full body':
        return '🔥';
      default:
        return '💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Workout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Import from URL or create a custom workout',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? const Color(0xFF3B82F6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'URL Import',
                              style: TextStyle(
                                color: _selectedTab == 0 ? Colors.white : const Color(0xFF6B7280),
                                fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? const Color(0xFF3B82F6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Create Custom',
                              style: TextStyle(
                                color: _selectedTab == 1 ? Colors.white : const Color(0xFF6B7280),
                                fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Content based on selected tab
                if (_selectedTab == 0) ...[
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Enter workout URL...',
                      prefixIcon: Icon(Icons.link, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addWorkout,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Scrape Workout'),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Custom workout creation coming soon!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
