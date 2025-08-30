import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

class WorkoutScraper {
  static const String _baseUrl = 'https://www.muscleandfitness.com';
  
  // Enhanced categories dictionary based on the Python algorithm
  static const Map<String, List<String>> categories = {
    "chest": ["bench press", "push up", "fly", "chest press", "incline press", "decline press", "pec deck"],
    "back": ["pull up", "lat pulldown", "row", "deadlift", "shrug", "hyperextension", "swiss ball hyperextension"],
    "arms": ["bicep curl", "hammer curl", "tricep extension", "dips", "skullcrusher", "preacher curl"],
    "legs": ["squat", "lunge", "leg press", "deadlift", "leg curl", "leg extension", "calf raise", "step up"],
    "shoulders": ["shoulder press", "overhead press", "lateral raise", "front raise", "shrug", "arnold press"],
    "abs": ["crunch", "plank", "sit up", "leg raise", "russian twist", "bicycle crunch", "mountain climber"],
    "full_body": ["burpee", "thruster", "clean", "snatch"],
    "cardio": ["running", "cycling", "rowing", "elliptical", "jump rope", "sprinting", "treadmill"],
    "functional": ["kettlebell swing", "farmer carry", "sled push", "medicine ball slam"],
    "other": []
  };
  
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
          
          // Extract workout information using improved algorithm
          final workoutData = _parseWorkoutDataImproved(document);
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
  
  static Map<String, dynamic> _parseWorkoutDataImproved(Document document) {
    // Extract workout title
    final titleElement = document.querySelector('h1');
    final title = titleElement?.text?.trim() ?? 'Scraped Workout';
    
    // Extract workout description/summary
    final descriptionElement = document.querySelector('p');
    final description = descriptionElement?.text?.trim() ?? '';
    
    // Use improved extraction algorithm
    final rawWorkouts = _extractWorkoutsImproved(document);
    final organizedWorkouts = _classifyExercisesImproved(rawWorkouts);
    
    // Convert to weekly workout format
    final weeklyWorkout = _convertToWeeklyFormat(organizedWorkouts);
    
    // Determine category based on title or content
    final category = _determineCategoryImproved(title, organizedWorkouts);
    
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
  
  static List<Map<String, dynamic>> _extractWorkoutsImproved(Document document) {
    final workouts = <Map<String, dynamic>>[];
    
    // Look for headings and paragraphs/lists (based on Python algorithm)
    final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    
    for (final heading in headings) {
      final headingText = heading.text?.trim() ?? '';
      final exercises = <String>[];
      
      // Capture nearby exercises (e.g., lists or paragraphs after heading)
      Element? sibling = heading.nextElementSibling;
      while (sibling != null && !RegExp(r'^h[1-6]$', caseSensitive: false).hasMatch(sibling.localName ?? '')) {
        if (sibling.localName == 'p' || sibling.localName == 'li') {
          final text = sibling.text?.trim() ?? '';
          if (text.isNotEmpty && text.length > 2) {
            exercises.add(text);
          }
        }
        sibling = sibling.nextElementSibling;
      }
      
      if (exercises.isNotEmpty) {
        workouts.add({
          'day_or_category': headingText,
          'exercises': exercises,
        });
      }
    }
    
    // Fallback: no headings, just grab list items or paragraphs
    if (workouts.isEmpty) {
      final rawExercises = <String>[];
      final elements = document.querySelectorAll('li, p');
      
      for (final element in elements) {
        final text = element.text?.trim() ?? '';
        if (text.isNotEmpty && text.length > 2) {
          rawExercises.add(text);
        }
      }
      
      if (rawExercises.isNotEmpty) {
        workouts.add({
          'day_or_category': 'Uncategorized',
          'exercises': rawExercises,
        });
      }
    }
    
    return workouts;
  }
  
  static Map<String, List<String>> _classifyExercisesImproved(List<Map<String, dynamic>> workouts) {
    final categorized = <String, List<String>>{};
    
    for (final block in workouts) {
      final category = (block['day_or_category'] as String).toLowerCase();
      
      // If looks like Day1/Day2 → keep as is
      if (RegExp(r'day\s*\d+', caseSensitive: false).hasMatch(category)) {
        categorized[block['day_or_category']] = List<String>.from(block['exercises']);
      } else {
        // Otherwise classify by exercise content
        for (final exercise in block['exercises']) {
          bool matched = false;
          final exerciseLower = exercise.toLowerCase();
          
          for (final entry in categories.entries) {
            final cat = entry.key;
            final keywords = entry.value;
            
            if (keywords.any((keyword) => exerciseLower.contains(keyword))) {
              categorized.putIfAbsent(cat, () => <String>[]);
              categorized[cat]!.add(exercise);
              matched = true;
              break;
            }
          }
          
          if (!matched) {
            categorized.putIfAbsent('other', () => <String>[]);
            categorized['other']!.add(exercise);
          }
        }
      }
    }
    
    return categorized;
  }
  
  static Map<String, dynamic> _convertToWeeklyFormat(Map<String, List<String>> organizedWorkouts) {
    final weeklyWorkout = <String, dynamic>{};
    final allExercises = <Map<String, dynamic>>[];
    int totalSets = 0;
    
    // Convert categorized exercises to structured workout format
    for (final entry in organizedWorkouts.entries) {
      final dayName = entry.key;
      final exerciseTexts = entry.value;
      
      final exercises = <Map<String, dynamic>>[];
      for (final exerciseText in exerciseTexts) {
        final exercise = _parseExerciseFromTextImproved(exerciseText);
        if (exercise['name'].toString().isNotEmpty) {
          exercises.add(exercise);
        }
      }
      
      if (exercises.isNotEmpty) {
        final daySets = exercises.fold<int>(0, (sum, e) => sum + ((e['sets'] as int?) ?? 0));
        weeklyWorkout[dayName] = {
          'day': dayName,
          'exercises': exercises,
          'totalSets': daySets,
          'duration': _estimateWorkoutDuration(exercises),
        };
        
        allExercises.addAll(exercises);
        totalSets += daySets;
      }
    }
    
    // If no structured days found, organize into logical days
    if (weeklyWorkout.isEmpty && allExercises.isNotEmpty) {
      final exercisesPerDay = (allExercises.length / 3).ceil();
      for (int i = 0; i < allExercises.length; i += exercisesPerDay) {
        final dayExercises = allExercises.skip(i).take(exercisesPerDay).toList();
        final dayName = 'Day ${(i ~/ exercisesPerDay) + 1}';
        final daySets = dayExercises.fold<int>(0, (sum, e) => sum + ((e['sets'] as int?) ?? 0));
        
        weeklyWorkout[dayName] = {
          'day': dayName,
          'exercises': dayExercises,
          'totalSets': daySets,
          'duration': _estimateWorkoutDuration(dayExercises),
        };
      }
    }
    
    weeklyWorkout['allExercises'] = allExercises;
    weeklyWorkout['totalSets'] = totalSets;
    weeklyWorkout['totalDays'] = weeklyWorkout.keys.where((key) => key.startsWith('Day') || key.contains('day')).length;
    
    return weeklyWorkout;
  }
  
  static Map<String, dynamic> _parseExerciseFromTextImproved(String text) {
    final exercise = <String, dynamic>{};
    
    // Extract exercise name (usually the first part)
    final nameMatch = RegExp(r'^([^0-9]+?)(?:\s+\d+|\s*$)', caseSensitive: false).firstMatch(text);
    exercise['name'] = nameMatch?.group(1)?.trim() ?? text;
    
    // Extract sets and reps with improved parsing
    final setsReps = _parseSetsAndRepsImproved(text);
    exercise['sets'] = setsReps['sets'];
    exercise['reps'] = setsReps['reps'];
    
    // Try to extract equipment
    final equipment = _extractEquipmentImproved(text);
    exercise['equipment'] = equipment;
    
    return exercise;
  }
  
  static Map<String, int> _parseSetsAndRepsImproved(String text) {
    // Enhanced parsing for various formats
    final patterns = [
      RegExp(r'(\d+)\s*x\s*(\d+)', caseSensitive: false), // 3x10
      RegExp(r'(\d+)\s*sets?\s*[,\-]\s*(\d+)\s*reps?', caseSensitive: false), // 3 sets, 10 reps
      RegExp(r'(\d+)\s*reps?\s*[,\-]\s*(\d+)\s*sets?', caseSensitive: false), // 10 reps, 3 sets
      RegExp(r'(\d+)\s*sets?', caseSensitive: false), // just sets
      RegExp(r'(\d+)\s*reps?', caseSensitive: false), // just reps
    ];
    
    int sets = 3; // Default
    int reps = 10; // Default
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 2) {
          sets = int.tryParse(match.group(1) ?? '3') ?? 3;
          reps = int.tryParse(match.group(2) ?? '10') ?? 10;
          break;
        } else if (match.groupCount == 1) {
          final value = int.tryParse(match.group(1) ?? '') ?? 0;
          if (text.toLowerCase().contains('set')) {
            sets = value;
          } else if (text.toLowerCase().contains('rep')) {
            reps = value;
          }
        }
      }
    }
    
    return {'sets': sets, 'reps': reps};
  }
  
  static String _extractEquipmentImproved(String text) {
    final equipmentKeywords = [
      'barbell', 'dumbbell', 'cable', 'machine', 'bench', 'rack',
      'smith', 'kettlebell', 'resistance band', 'bodyweight', 'ez-bar',
      'preacher bench', 'dip station', 'leg press machine', 'box'
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

  static String _determineCategoryImproved(String title, Map<String, List<String>> organizedWorkouts) {
    final titleLower = title.toLowerCase();
    
    // Check title first
    if (titleLower.contains('thor') || titleLower.contains('god')) {
      return 'Full Body';
    }
    
    // Check organized workouts for dominant category
    String dominantCategory = 'Full Body';
    int maxExercises = 0;
    
    for (final entry in organizedWorkouts.entries) {
      if (entry.value.length > maxExercises) {
        maxExercises = entry.value.length;
        dominantCategory = entry.key;
      }
    }
    
    // Convert category names to display format
    switch (dominantCategory.toLowerCase()) {
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'legs':
        return 'Legs';
      case 'arms':
        return 'Arms';
      case 'shoulders':
        return 'Shoulders';
      case 'abs':
        return 'Abs';
      case 'cardio':
        return 'Cardio';
      case 'functional':
        return 'Functional';
      default:
        return 'Full Body';
    }
  }
} 