import 'package:flutter/material.dart';
import 'main.dart';

class QuickActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutCardNew extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const WorkoutCardNew({
    super.key,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = workout.totalSets > 0
        ? workout.completedSets / workout.totalSets
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: workout.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      workout.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.category,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${workout.completedSets}/${workout.exercises.length} exercises',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFF3B82F6),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bottom row with time and difficulty
            Row(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.duration} min',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Hard',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          progress >= 1.0 ? Icons.replay : Icons.play_arrow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          progress >= 1.0 ? 'Repeat' : 'Start',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (progress >= 1.0) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
