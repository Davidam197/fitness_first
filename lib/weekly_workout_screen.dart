import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WeeklyWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workoutData;
  final Function(Map<String, dynamic>) onWorkoutSaved;

  const WeeklyWorkoutScreen({
    super.key,
    required this.workoutData,
    required this.onWorkoutSaved,
  });

  @override
  State<WeeklyWorkoutScreen> createState() => _WeeklyWorkoutScreenState();
}

class _WeeklyWorkoutScreenState extends State<WeeklyWorkoutScreen> {
  late Map<String, dynamic> workoutData;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    workoutData = Map<String, dynamic>.from(widget.workoutData);
  }

  List<String> get workoutDays {
    final weeklyWorkout = workoutData['weeklyWorkout'] as Map<String, dynamic>;
    return weeklyWorkout.keys
        .where((key) => key != 'allExercises' && key != 'totalSets' && key != 'totalDays')
        .toList();
  }

  Map<String, dynamic> getWeeklyWorkout() {
    return workoutData['weeklyWorkout'] as Map<String, dynamic>;
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
    final weeklyWorkout = getWeeklyWorkout();
    final days = workoutDays;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDayTabs(days),
            Expanded(
              child: _buildDayContent(days[selectedDayIndex], weeklyWorkout),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveWorkout,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save Workout'),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader() {
    final gradient = _getGradientForCategory(workoutData['category']);
    final emoji = _getEmojiForCategory(workoutData['category']);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workoutDays.length} Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            workoutData['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            workoutData['description'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.fitness_center,
                value: workoutData['totalSets'].toString(),
                label: 'Total Sets',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.calendar_today,
                value: workoutDays.length.toString(),
                label: 'Days',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.access_time,
                value: '${_calculateTotalDuration()}m',
                label: 'Duration',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildDayTabs(List<String> days) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = index == selectedDayIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDayIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Text(
                day,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent(String day, Map<String, dynamic> weeklyWorkout) {
    final dayData = weeklyWorkout[day] as Map<String, dynamic>;
    final exercises = dayData['exercises'] as List<Map<String, dynamic>>;
    final totalSets = dayData['totalSets'] as int;
    final duration = dayData['duration'] as int;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Row(
                  children: [
                    _DayStat(
                      icon: Icons.fitness_center,
                      value: totalSets.toString(),
                      label: 'Sets',
                    ),
                    const SizedBox(width: 16),
                    _DayStat(
                      icon: Icons.access_time,
                      value: '${duration}m',
                      label: 'Time',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Exercises list
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  index: index,
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 400),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalDuration() {
    final weeklyWorkout = getWeeklyWorkout();
    int totalDuration = 0;
    
    for (final day in workoutDays) {
      final dayData = weeklyWorkout[day] as Map<String, dynamic>;
      totalDuration += dayData['duration'] as int;
    }
    
    return totalDuration;
  }

  void _saveWorkout() {
    // Convert weekly workout to a single workout for saving
    final allExercises = getWeeklyWorkout()['allExercises'] as List<Map<String, dynamic>>;
    final exerciseNames = allExercises.map((e) => e['name'].toString()).toList();
    
    final workout = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': workoutData['title'],
      'category': workoutData['category'],
      'exercises': exerciseNames,
      'totalSets': workoutData['totalSets'],
      'duration': _calculateTotalDuration(),
      'weeklyWorkout': workoutData['weeklyWorkout'],
      'isWeeklyPlan': true,
    };
    
    widget.onWorkoutSaved(workout);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Weekly workout saved successfully!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    
    Navigator.of(context).pop();
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
            fontSize: 16,
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

class _DayStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DayStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6B7280),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final int index;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise['sets']} sets × ${exercise['reps']} reps',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (exercise['equipment'] != null && exercise['equipment'].toString().isNotEmpty)
                    Text(
                      exercise['equipment'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${exercise['sets']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
