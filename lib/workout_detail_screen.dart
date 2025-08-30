import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> workoutData;
  final Function(Map<String, dynamic>) onWorkoutUpdated;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutData,
    required this.onWorkoutUpdated,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Map<String, dynamic> workoutData;
  late TextEditingController nameController;
  late TextEditingController categoryController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    workoutData = Map<String, dynamic>.from(widget.workoutData);
    nameController = TextEditingController(text: workoutData['title']);
    categoryController = TextEditingController(text: workoutData['category']);
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  void _updateExercise(int index, String field, dynamic value) {
    setState(() {
      workoutData['exercises'][index][field] = value;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveWorkout() {
    workoutData['title'] = nameController.text;
    workoutData['category'] = categoryController.text;
    widget.onWorkoutUpdated(workoutData);
    
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Workout updated successfully!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    
    Navigator.of(context).pop();
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

  String _shortenWorkoutName(String name) {
    if (name.length <= 20) return name;
    
    // Common workout name patterns to shorten
    final patterns = {
      'Upper Body Blast': 'Upper Body',
      'HIIT Cardio': 'HIIT',
      'Core Destroyer': 'Core',
      'Leg Day Power': 'Leg Day',
      'Full Body Burn': 'Full Body',
      'Strength Training': 'Strength',
      'Cardio Workout': 'Cardio',
      'Muscle Building': 'Muscle',
      'Fat Burning': 'Fat Burn',
      'Endurance Training': 'Endurance',
    };
    
    // Check for exact matches first
    if (patterns.containsKey(name)) {
      return patterns[name]!;
    }
    
    // Check for partial matches
    for (final entry in patterns.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If no pattern match, truncate intelligently
    final words = name.split(' ');
    if (words.length > 2) {
      return '${words[0]} ${words[1]}';
    }
    
    return name.length > 20 ? '${name.substring(0, 17)}...' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWorkoutInfo(),
            Expanded(
              child: _buildExercisesGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEditing ? FloatingActionButton.extended(
        onPressed: _saveWorkout,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save Workout'),
        elevation: 4,
      ) : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Workout Details',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${workoutData['exercises'].length} Exercises',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    final gradient = _getGradientForCategory(workoutData['category']);
    final emoji = _getEmojiForCategory(workoutData['category']);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Row(
                children: [
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
                      workoutData['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _toggleEdit,
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_isEditing)
            TextField(
              controller: nameController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )
          else
            Text(
              workoutData['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          
          const SizedBox(height: 24),
          
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
                icon: Icons.sports_gymnastics,
                value: workoutData['exercises'].length.toString(),
                label: 'Exercises',
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.source,
                value: workoutData['source'] ?? 'Unknown',
                label: 'Source',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildExercisesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: workoutData['exercises'].length,
        itemBuilder: (context, index) {
          final exercise = workoutData['exercises'][index];
          return _ExerciseCard(
            exercise: exercise,
            index: index,
            onUpdate: _updateExercise,
          ).animate().fadeIn(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 400),
          );
        },
      ),
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

class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final Function(int, String, dynamic) onUpdate;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.onUpdate,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late TextEditingController nameController;
  late TextEditingController setsController;
  late TextEditingController repsController;
  late TextEditingController equipmentController;
  
  bool isActive = false;
  Timer? timer;
  int remainingSeconds = 0;
  int completedSets = 0;
  bool isEditing = false;

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
    
    nameController = TextEditingController(text: widget.exercise['name']);
    setsController = TextEditingController(text: widget.exercise['sets'].toString());
    repsController = TextEditingController(text: widget.exercise['reps'].toString());
    equipmentController = TextEditingController(text: widget.exercise['equipment'] ?? '');
  }

  @override
  void dispose() {
    _animationController.dispose();
    timer?.cancel();
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    equipmentController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      isActive = true;
      remainingSeconds = 300; // 5 minutes default
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            timer.cancel();
            isActive = false;
          }
        });
      });
    });
  }

  void _pauseExercise() {
    setState(() {
      isActive = false;
      timer?.cancel();
    });
  }

  void _completeSet() {
    setState(() {
      if (completedSets < widget.exercise['sets']) {
        completedSets++;
      }
    });
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveEdit() {
    widget.onUpdate(widget.index, 'name', nameController.text);
    widget.onUpdate(widget.index, 'sets', int.tryParse(setsController.text) ?? 0);
    widget.onUpdate(widget.index, 'reps', int.tryParse(repsController.text) ?? 0);
    widget.onUpdate(widget.index, 'equipment', equipmentController.text);
    
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.exercise['sets'] > 0
        ? completedSets / widget.exercise['sets']
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                                                        Row(
                                children: [
                                  IconButton(
                                    onPressed: _toggleEdit,
                                    icon: Icon(
                                      isEditing ? Icons.close : Icons.edit,
                                      color: const Color(0xFF6B7280),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      if (isEditing)
                        TextField(
                          controller: nameController,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        )
                      else
                        Text(
                          widget.exercise['name'],
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 6),
                      
                      if (isEditing)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: setsController,
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Sets',
                                  labelStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: repsController,
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  labelStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${widget.exercise['sets']} sets × ${widget.exercise['reps']} reps',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      
                      const SizedBox(height: 6),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedSets/${widget.exercise['sets']}',
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isActive)
                                Text(
                                  '${(remainingSeconds / 60).floor()}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
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
                      
                      const SizedBox(height: 6),
                      
                      Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isActive ? _pauseExercise : _startExercise,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  child: Icon(
                                    isActive ? Icons.pause : Icons.play_arrow,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _completeSet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  minimumSize: const Size(36, 36),
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
    );
  }
} 