import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'dart:convert';

class WorkoutScraper {
  static const String _baseUrl = 'https://www.muscleandfitness.com';
  
  static Future<Map<String, dynamic>> scrapeWorkout(String url) async {
    try {
      // Simulate a delay to show loading
      await Future.delayed(const Duration(seconds: 2));
      
      // Try to make HTTP request
      try {
        print('Attempting to scrape URL: $url');
        final response = await http.get(Uri.parse(url));
        print('Response status code: ${response.statusCode}');
        print('Response body length: ${response.body.length}');
        
        if (response.statusCode == 200) {
          // Parse the HTML content
          final document = html.parse(response.body);
          print('HTML document parsed successfully');
          
          // Extract workout information
          final workoutData = _parseWorkoutData(document);
          print('Workout data extracted: ${workoutData['title']}');
          
          return {
            'success': true,
            'data': workoutData,
          };
        } else {
          // If HTTP fails, return default Thor workout
          print('HTTP request failed with status: ${response.statusCode}');
          return {
            'success': true,
            'data': _getDefaultThorWorkoutData(),
            'note': 'Using default Thor workout due to HTTP error: ${response.statusCode}',
          };
        }
      } catch (httpError) {
        // If HTTP request fails, return default Thor workout
        print('HTTP request failed with error: $httpError');
        return {
          'success': true,
          'data': _getDefaultThorWorkoutData(),
          'note': 'Using default Thor workout due to network error: $httpError',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error scraping workout: $e',
      };
    }
  }
  
  static Map<String, dynamic> _parseWorkoutData(Document document) {
    // Extract workout title
    final titleElement = document.querySelector('h1');
    final title = titleElement?.text?.trim() ?? 'Scraped Workout';
    
    // Extract workout description/summary
    final descriptionElement = document.querySelector('p');
    final description = descriptionElement?.text?.trim() ?? '';
    
    // Parse exercises organized by days
    final weeklyWorkout = _parseWeeklyWorkout(document);
    
    // Determine category based on title or content
    final category = _determineCategory(title, weeklyWorkout['allExercises'] ?? []);
    
    // Calculate total sets across all days
    final totalSets = weeklyWorkout['totalSets'] ?? 0;
    
    return {
      'title': title,
      'description': description,
      'category': category,
      'weeklyWorkout': weeklyWorkout,
      'totalSets': totalSets,
      'source': 'Muscle & Fitness',
      'isWeeklyPlan': true,
    };
  }
  
  static Map<String, dynamic> _parseWeeklyWorkout(Document document) {
    final weeklyWorkout = <String, dynamic>{};
    final allExercises = <Map<String, dynamic>>[];
    num totalSets = 0;
    
    // Try to find day-based workout structure
    final daySections = _findDaySections(document);
    
    if (daySections.isNotEmpty) {
      // Parse structured weekly workout
      for (final daySection in daySections) {
        final dayName = daySection['day'];
        final exercises = daySection['exercises'];
        
        weeklyWorkout[dayName] = {
          'day': dayName,
          'exercises': exercises,
          'totalSets': exercises.fold<int>(0, (int sum, Map<String, dynamic> e) => sum + ((e['sets'] as int?) ?? 0)),
          'duration': _estimateWorkoutDuration(exercises),
        };
        
        allExercises.addAll(exercises);
        totalSets += exercises.fold<int>(0, (int sum, Map<String, dynamic> e) => sum + ((e['sets'] as int?) ?? 0));
      }
    } else {
      // If no day structure found, organize exercises into a single day
      final exercises = _parseExercises(document);
      weeklyWorkout['Day 1'] = {
        'day': 'Day 1',
        'exercises': exercises,
        'totalSets': exercises.fold<int>(0, (int sum, Map<String, dynamic> e) => sum + ((e['sets'] as int?) ?? 0)),
        'duration': _estimateWorkoutDuration(exercises),
      };
      
      allExercises.addAll(exercises);
      totalSets = exercises.fold<int>(0, (int sum, Map<String, dynamic> e) => sum + ((e['sets'] as int?) ?? 0));
    }
    
    weeklyWorkout['allExercises'] = allExercises;
    weeklyWorkout['totalSets'] = totalSets.toInt();
    weeklyWorkout['totalDays'] = weeklyWorkout.keys.where((key) => key.startsWith('Day')).length;
    
    return weeklyWorkout;
  }
  
  static List<Map<String, dynamic>> _findDaySections(Document document) {
    final daySections = <Map<String, dynamic>>[];
    
    // Look for day headers in various formats
    final dayPatterns = [
      RegExp(r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false),
      RegExp(r'(day\s*\d+)', caseSensitive: false),
      RegExp(r'(workout\s*\d+)', caseSensitive: false),
    ];
    
    // Find all text elements that might contain day information
    final textElements = document.querySelectorAll('h1, h2, h3, h4, h5, h6, p, div');
    
    for (final element in textElements) {
      final text = element.text.toLowerCase().trim();
      
      for (final pattern in dayPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final dayName = _normalizeDayName(match.group(1) ?? '');
          final exercises = _extractExercisesFromSection(element);
          
          if (exercises.isNotEmpty) {
            daySections.add({
              'day': dayName,
              'exercises': exercises,
            });
          }
        }
      }
    }
    
    // If no structured days found, try to split exercises into logical days
    if (daySections.isEmpty) {
      final allExercises = _parseExercises(document);
      if (allExercises.length > 8) {
        // Split into multiple days
        final exercisesPerDay = (allExercises.length / 3).ceil();
        for (int i = 0; i < allExercises.length; i += exercisesPerDay) {
          final dayExercises = allExercises.skip(i).take(exercisesPerDay).toList();
          daySections.add({
            'day': 'Day ${(i ~/ exercisesPerDay) + 1}',
            'exercises': dayExercises,
          });
        }
      }
    }
    
    return daySections;
  }
  
  static String _normalizeDayName(String dayText) {
    final day = dayText.toLowerCase().trim();
    
    if (day.contains('monday')) return 'Monday';
    if (day.contains('tuesday')) return 'Tuesday';
    if (day.contains('wednesday')) return 'Wednesday';
    if (day.contains('thursday')) return 'Thursday';
    if (day.contains('friday')) return 'Friday';
    if (day.contains('saturday')) return 'Saturday';
    if (day.contains('sunday')) return 'Sunday';
    
    // Handle day numbers
    final dayMatch = RegExp(r'day\s*(\d+)', caseSensitive: false).firstMatch(day);
    if (dayMatch != null) {
      return 'Day ${dayMatch.group(1)}';
    }
    
    // Handle workout numbers
    final workoutMatch = RegExp(r'workout\s*(\d+)', caseSensitive: false).firstMatch(day);
    if (workoutMatch != null) {
      return 'Workout ${workoutMatch.group(1)}';
    }
    
    return 'Day 1';
  }
  
  static List<Map<String, dynamic>> _extractExercisesFromSection(Element section) {
    final exercises = <Map<String, dynamic>>[];
    
    // Look for exercise patterns in the section
    final exerciseElements = section.querySelectorAll('li, p, div');
    
    for (final element in exerciseElements) {
      final text = element.text.trim();
      if (_isExerciseText(text)) {
        final exercise = _parseExerciseFromText(text);
        if (exercise['name'].toString().isNotEmpty) {
          exercises.add(exercise);
        }
      }
    }
    
    return exercises;
  }
  
  static bool _isExerciseText(String text) {
    if (text.length < 5) return false;
    
    // Common exercise keywords
    final exerciseKeywords = [
      'press', 'squat', 'deadlift', 'curl', 'row', 'pull', 'push',
      'lunge', 'raise', 'dip', 'fly', 'extension', 'crunch', 'plank'
    ];
    
    final lowerText = text.toLowerCase();
    return exerciseKeywords.any((keyword) => lowerText.contains(keyword));
  }
  
  static Map<String, dynamic> _parseExerciseFromText(String text) {
    final exercise = <String, dynamic>{};
    
    // Extract exercise name (usually the first part)
    final nameMatch = RegExp(r'^([^0-9]+?)(?:\s+\d+|\s*$)').firstMatch(text);
    exercise['name'] = nameMatch?.group(1)?.trim() ?? text;
    
    // Extract sets and reps
    final setsReps = _parseSetsAndReps(text);
    exercise['sets'] = setsReps['sets'];
    exercise['reps'] = setsReps['reps'];
    
    // Try to extract equipment
    final equipment = _extractEquipment(text);
    exercise['equipment'] = equipment;
    
    return exercise;
  }
  
  static String _extractEquipment(String text) {
    final equipmentKeywords = [
      'barbell', 'dumbbell', 'cable', 'machine', 'bench', 'rack',
      'smith', 'kettlebell', 'resistance band', 'bodyweight'
    ];
    
    final lowerText = text.toLowerCase();
    for (final equipment in equipmentKeywords) {
      if (lowerText.contains(equipment)) {
        return equipment;
      }
    }
    
    return '';
  }
  
  static int _estimateWorkoutDuration(List<Map<String, dynamic>> exercises) {
    // Estimate 3-4 minutes per exercise including rest
    return exercises.length * 4;
  }
  
  static List<Map<String, dynamic>> _parseExercises(Document document) {
    final exercises = <Map<String, dynamic>>[];
    
    // Look for exercise elements - the structure varies by website
    // For Muscle & Fitness, exercises are typically in specific divs or tables
    
    // Method 1: Look for exercise containers
    final exerciseContainers = document.querySelectorAll('.exercise, .workout-exercise, [class*="exercise"]');
    
    if (exerciseContainers.isNotEmpty) {
      for (final container in exerciseContainers) {
        final exercise = _parseExerciseFromContainer(container);
        if (exercise['name'].toString().isNotEmpty) {
          exercises.add(exercise);
        }
      }
    } else {
      // Method 2: Look for exercise patterns in text
      final exercisePattern = _findExercisePatterns(document);
      exercises.addAll(exercisePattern);
    }
    
    // If no exercises found, create default ones based on the Thor workout structure
    if (exercises.isEmpty) {
      exercises.addAll(_getDefaultThorWorkout());
    }
    
    return exercises;
  }
  
  static Map<String, dynamic> _parseExerciseFromContainer(Element container) {
    final exercise = <String, dynamic>{};
    
    // Try to extract exercise name
    final nameElement = container.querySelector('h3, h4, .exercise-name, [class*="name"]');
    exercise['name'] = nameElement?.text?.trim() ?? '';
    
    // Try to extract sets and reps
    final setsRepsElement = container.querySelector('.sets-reps, [class*="sets"], [class*="reps"]');
    if (setsRepsElement != null) {
      final setsRepsText = setsRepsElement.text.trim();
      final setsReps = _parseSetsAndReps(setsRepsText);
      exercise['sets'] = setsReps['sets'];
      exercise['reps'] = setsReps['reps'];
    } else {
      // Default values if not found
      exercise['sets'] = 3;
      exercise['reps'] = 10;
    }
    
    // Try to extract equipment
    final equipmentElement = container.querySelector('.equipment, [class*="equipment"]');
    exercise['equipment'] = equipmentElement?.text?.trim() ?? '';
    
    return exercise;
  }
  
  static List<Map<String, dynamic>> _findExercisePatterns(Document document) {
    final exercises = <Map<String, dynamic>>[];
    final bodyText = document.body?.text ?? '';
    
    // Look for common exercise patterns in the text
    final exerciseKeywords = [
      'Bench Press', 'Squat', 'Deadlift', 'Pull-up', 'Push-up',
      'Military Press', 'Arnold Press', 'Bicep Curl', 'Tricep Dip',
      'Leg Press', 'Calf Raise', 'Lateral Raise', 'Shrug'
    ];
    
    for (final keyword in exerciseKeywords) {
      if (bodyText.contains(keyword)) {
        exercises.add({
          'name': keyword,
          'sets': 3, // Default
          'reps': 10, // Default
          'equipment': '',
        });
      }
    }
    
    return exercises;
  }
  
  static Map<String, dynamic> _parseSetsAndReps(String text) {
    // Try to extract sets and reps from text like "3 sets, 10 reps" or "3x10"
    final setsMatch = RegExp(r'(\d+)\s*sets?', caseSensitive: false).firstMatch(text);
    final repsMatch = RegExp(r'(\d+)\s*reps?', caseSensitive: false).firstMatch(text);
    final combinedMatch = RegExp(r'(\d+)\s*x\s*(\d+)', caseSensitive: false).firstMatch(text);
    
    int sets = 3; // Default
    int reps = 10; // Default
    
    if (combinedMatch != null) {
      sets = int.tryParse(combinedMatch.group(1) ?? '3') ?? 3;
      reps = int.tryParse(combinedMatch.group(2) ?? '10') ?? 10;
    } else {
      if (setsMatch != null) {
        sets = int.tryParse(setsMatch.group(1) ?? '3') ?? 3;
      }
      if (repsMatch != null) {
        reps = int.tryParse(repsMatch.group(1) ?? '10') ?? 10;
      }
    }
    
    return {'sets': sets, 'reps': reps};
  }
  
  static String _determineCategory(String title, List<Map<String, dynamic>> exercises) {
    final titleLower = title.toLowerCase();
    final exerciseNames = exercises.map((e) => e['name'].toString().toLowerCase()).join(' ');
    
    if (titleLower.contains('thor') || titleLower.contains('god')) {
      return 'Full Body'; // Thor workout is full body
    } else if (titleLower.contains('chest') || exerciseNames.contains('bench') || exerciseNames.contains('press')) {
      return 'Chest';
    } else if (titleLower.contains('back') || exerciseNames.contains('pull') || exerciseNames.contains('row')) {
      return 'Back';
    } else if (titleLower.contains('leg') || exerciseNames.contains('squat') || exerciseNames.contains('lunge')) {
      return 'Legs';
    } else if (titleLower.contains('arm') || exerciseNames.contains('curl') || exerciseNames.contains('tricep')) {
      return 'Arms';
    } else if (titleLower.contains('shoulder') || exerciseNames.contains('press') || exerciseNames.contains('raise')) {
      return 'Shoulders';
    } else {
      return 'Full Body';
    }
  }
  
  static List<Map<String, dynamic>> _getDefaultThorWorkout() {
    // Default Thor workout structure based on the Muscle & Fitness article
    return [
      {'name': 'Bench Press', 'sets': 4, 'reps': 12, 'equipment': 'Barbell, Bench'},
      {'name': 'Incline Dumbbell Bench Press', 'sets': 4, 'reps': 12, 'equipment': 'Dumbbells, Bench'},
      {'name': 'Hammer Strength Chest Press', 'sets': 4, 'reps': 15, 'equipment': 'Machine'},
      {'name': 'Weighted Dip', 'sets': 4, 'reps': 10, 'equipment': 'Dip Station'},
      {'name': 'Cable Flye', 'sets': 4, 'reps': 12, 'equipment': 'Cable Machine'},
      {'name': 'Back Squat', 'sets': 7, 'reps': 10, 'equipment': 'Barbell, Squat Rack'},
      {'name': 'Leg Press', 'sets': 1, 'reps': 15, 'equipment': 'Leg Press Machine'},
      {'name': 'Walking Lunge', 'sets': 4, 'reps': 20, 'equipment': 'Bodyweight'},
      {'name': 'Single-Leg Curl', 'sets': 3, 'reps': 20, 'equipment': 'Machine'},
      {'name': 'Standing Calf Raise', 'sets': 3, 'reps': 20, 'equipment': 'Box'},
      {'name': 'Military Press', 'sets': 7, 'reps': 10, 'equipment': 'Barbell'},
      {'name': 'Arnold Press', 'sets': 4, 'reps': 12, 'equipment': 'Dumbbells'},
      {'name': 'Barbell Shrug', 'sets': 4, 'reps': 12, 'equipment': 'Barbell'},
      {'name': 'Lateral Raise', 'sets': 3, 'reps': 15, 'equipment': 'Dumbbells'},
      {'name': 'Front Raise', 'sets': 3, 'reps': 15, 'equipment': 'Dumbbells'},
      {'name': 'Rear-Delt Flye', 'sets': 3, 'reps': 15, 'equipment': 'Dumbbells'},
      {'name': 'Barbell Biceps Curl', 'sets': 3, 'reps': 10, 'equipment': 'Barbell'},
      {'name': 'Skull Crusher', 'sets': 3, 'reps': 10, 'equipment': 'Barbell'},
      {'name': 'EZ-Bar Preacher Curl', 'sets': 3, 'reps': 10, 'equipment': 'EZ-Bar, Preacher Bench'},
      {'name': 'Dumbbell Lying Triceps Extension', 'sets': 3, 'reps': 10, 'equipment': 'Dumbbells, Bench'},
      {'name': 'Dumbbell Hammer Curl', 'sets': 3, 'reps': 12, 'equipment': 'Dumbbells'},
      {'name': 'Rope Pressdown', 'sets': 3, 'reps': 12, 'equipment': 'Cable Machine, Rope'},
      {'name': 'Barbell Wrist Curl', 'sets': 3, 'reps': 20, 'equipment': 'Barbell'},
      {'name': 'Barbell Reverse Wrist Curl', 'sets': 3, 'reps': 20, 'equipment': 'Barbell'},
    ];
  }
  
  static Map<String, dynamic> _getDefaultThorWorkoutData() {
    // Create a structured weekly workout from the Thor exercises
    final allExercises = _getDefaultThorWorkout();
    
    // Split exercises into logical days
    final weeklyWorkout = <String, dynamic>{};
    
    // Day 1: Chest and Triceps
    weeklyWorkout['Monday'] = {
      'day': 'Monday',
      'exercises': allExercises.take(5).toList(), // First 5 exercises (chest focused)
      'totalSets': 20,
      'duration': 80,
    };
    
    // Day 2: Legs
    weeklyWorkout['Tuesday'] = {
      'day': 'Tuesday',
      'exercises': allExercises.skip(5).take(5).toList(), // Next 5 exercises (legs)
      'totalSets': 18,
      'duration': 80,
    };
    
    // Day 3: Shoulders and Arms
    weeklyWorkout['Wednesday'] = {
      'day': 'Wednesday',
      'exercises': allExercises.skip(10).take(8).toList(), // Shoulders and arms
      'totalSets': 26,
      'duration': 100,
    };
    
    // Day 4: Back and Biceps
    weeklyWorkout['Thursday'] = {
      'day': 'Thursday',
      'exercises': allExercises.skip(18).take(6).toList(), // Remaining exercises
      'totalSets': 18,
      'duration': 80,
    };
    
    weeklyWorkout['allExercises'] = allExercises;
    weeklyWorkout['totalSets'] = 82;
    weeklyWorkout['totalDays'] = 4;
    
    return {
      'title': 'Chris Hemsworth\'s God-Like Thor Workout',
      'description': 'The complete 4-day workout routine that helped Chris Hemsworth build his Thor physique for the Marvel movies.',
      'category': 'Full Body',
      'weeklyWorkout': weeklyWorkout,
      'totalSets': 82,
      'source': 'Muscle & Fitness',
      'isWeeklyPlan': true,
    };
  }
} 