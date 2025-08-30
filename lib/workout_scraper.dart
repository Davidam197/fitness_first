import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';

class WorkoutScraper {
  static const String _baseUrl = 'https://www.muscleandfitness.com';
  
  // Category keywords for fallback classification (based on the new Python algorithm)
  static const Map<String, List<String>> categories = {
    "chest": ["bench", "fly", "press", "dip", "weighted dip"],
    "back": ["squat", "deadlift", "row", "lunge", "pullup", "hyperextension"],
    "legs": ["squat", "leg press", "lunge", "calf raise", "leg extension", "curl"],
    "shoulders": ["press", "arnold", "raise", "shrug", "deltoid"],
    "arms": ["curl", "tricep", "bicep", "skull crusher", "hammer"],
    "abs": ["crunch", "plank", "sit up", "leg raise"],
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
    
    // Try different extraction strategies in order of preference
    Map<String, List<Map<String, dynamic>>> workoutData;
    String extractionMethod = 'fallback';
    
    // Strategy 1: Thor-style workout extraction (Day-based structure)
    workoutData = _extractThorWorkout(document);
    if (workoutData.isNotEmpty) {
      extractionMethod = 'thor_style';
    } else {
      // Strategy 2: Generic workout extraction (heading-based structure)
      workoutData = _extractGenericWorkout(document);
      if (workoutData.isNotEmpty) {
        extractionMethod = 'generic_heading';
      } else {
        // Strategy 3: List-based extraction (fallback)
        workoutData = _extractListBasedWorkout(document);
        if (workoutData.isNotEmpty) {
          extractionMethod = 'list_based';
        } else {
          // Strategy 4: Default Thor workout
          final defaultData = _getDefaultThorWorkoutData()['weeklyWorkout'] as Map<String, dynamic>;
          workoutData = _convertDefaultToWorkoutData(defaultData);
          extractionMethod = 'default';
        }
      }
    }
    
    // Convert to weekly workout format
    final weeklyWorkout = _convertToUniversalFormat(workoutData, extractionMethod);
    
    // Determine category based on title or content
    final category = _determineCategoryUniversal(title, workoutData);
    
    // Calculate total sets across all days
    final totalSets = weeklyWorkout['totalSets'] ?? 0;
    
    return {
      'title': title,
      'description': description,
      'category': category,
      'weeklyWorkout': weeklyWorkout,
      'totalSets': totalSets,
      'source': 'Dynamic Scraper',
      'isWeeklyPlan': true,
      'extractionMethod': extractionMethod,
    };
  }
  
  static Map<String, List<Map<String, dynamic>>> _extractThorWorkout(Document document) {
    final data = <String, List<Map<String, dynamic>>>{};
    String? currentDay;

    // Find all h2, h3, h4 tags (based on the Python algorithm)
    final tags = document.querySelectorAll('h2, h3, h4');
    
    for (final tag in tags) {
      final text = tag.text?.trim() ?? '';
      
      // Check if this is a day header
      if (RegExp(r'Day \d+', caseSensitive: false).hasMatch(text)) {
        currentDay = text;
        data[currentDay] = [];
      } else if (currentDay != null) {
        // If we have a current day and this is h3 or h4, it's likely an exercise
        if (tag.localName == 'h3' || tag.localName == 'h4') {
          final exercise = text;
          final category = _classifyExercise(exercise);
          data[currentDay]!.add({
            'exercise': exercise,
            'category': category,
          });
        }
      }
    }

    return data;
  }
  
  static String _classifyExercise(String name) {
    final nameLower = name.toLowerCase();
    for (final entry in categories.entries) {
      final cat = entry.key;
      final keywords = entry.value;
      if (keywords.any((keyword) => nameLower.contains(keyword))) {
        return cat;
      }
    }
    return 'other';
  }
  
  static Map<String, List<Map<String, dynamic>>> _extractGenericWorkout(Document document) {
    final data = <String, List<Map<String, dynamic>>>{};
    
    // Look for various heading patterns that might indicate workout sections
    final headingPatterns = [
      RegExp(r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', caseSensitive: false),
      RegExp(r'(day\s*\d+)', caseSensitive: false),
      RegExp(r'(workout\s*\d+)', caseSensitive: false),
      RegExp(r'(chest|back|legs|arms|shoulders|abs)', caseSensitive: false),
      RegExp(r'(push|pull|upper|lower)', caseSensitive: false),
    ];
    
    final headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
    
    for (final heading in headings) {
      final headingText = heading.text?.trim() ?? '';
      if (headingText.isEmpty) continue;
      
      // Check if this heading matches any of our patterns
      bool isWorkoutSection = false;
      String sectionName = headingText;
      
      for (final pattern in headingPatterns) {
        final match = pattern.firstMatch(headingText.toLowerCase());
        if (match != null) {
          isWorkoutSection = true;
          sectionName = _normalizeSectionName(headingText);
          break;
        }
      }
      
      if (isWorkoutSection) {
        final exercises = _extractExercisesFromSection(heading);
        if (exercises.isNotEmpty) {
          data[sectionName] = exercises;
        }
      }
    }
    
    return data;
  }
  
  static String _normalizeSectionName(String name) {
    final lowerName = name.toLowerCase();
    
    // Normalize day names
    if (lowerName.contains('monday')) return 'Monday';
    if (lowerName.contains('tuesday')) return 'Tuesday';
    if (lowerName.contains('wednesday')) return 'Wednesday';
    if (lowerName.contains('thursday')) return 'Thursday';
    if (lowerName.contains('friday')) return 'Friday';
    if (lowerName.contains('saturday')) return 'Saturday';
    if (lowerName.contains('sunday')) return 'Sunday';
    
    // Normalize day numbers
    final dayMatch = RegExp(r'day\s*(\d+)', caseSensitive: false).firstMatch(lowerName);
    if (dayMatch != null) {
      return 'Day ${dayMatch.group(1)}';
    }
    
    // Normalize workout numbers
    final workoutMatch = RegExp(r'workout\s*(\d+)', caseSensitive: false).firstMatch(lowerName);
    if (workoutMatch != null) {
      return 'Workout ${workoutMatch.group(1)}';
    }
    
    // Normalize muscle groups
    if (lowerName.contains('chest')) return 'Chest';
    if (lowerName.contains('back')) return 'Back';
    if (lowerName.contains('legs')) return 'Legs';
    if (lowerName.contains('arms')) return 'Arms';
    if (lowerName.contains('shoulders')) return 'Shoulders';
    if (lowerName.contains('abs')) return 'Abs';
    if (lowerName.contains('push')) return 'Push';
    if (lowerName.contains('pull')) return 'Pull';
    if (lowerName.contains('upper')) return 'Upper Body';
    if (lowerName.contains('lower')) return 'Lower Body';
    
    return name;
  }
  
  static List<Map<String, dynamic>> _extractExercisesFromSection(Element section) {
    final exercises = <Map<String, dynamic>>[];
    
    // Look for exercises in various formats after the heading
    Element? current = section.nextElementSibling;
    while (current != null && !_isNewSection(current)) {
      if (_isExerciseElement(current)) {
        final exerciseText = current.text?.trim() ?? '';
        if (exerciseText.isNotEmpty && _isExerciseText(exerciseText)) {
          final category = _classifyExercise(exerciseText);
          exercises.add({
            'exercise': exerciseText,
            'category': category,
          });
        }
      }
      current = current.nextElementSibling;
    }
    
    return exercises;
  }
  
  static bool _isNewSection(Element element) {
    final tagName = element.localName?.toLowerCase() ?? '';
    return tagName.startsWith('h') && int.tryParse(tagName.substring(1)) != null;
  }
  
  static bool _isExerciseElement(Element element) {
    final tagName = element.localName?.toLowerCase() ?? '';
    return tagName == 'li' || tagName == 'p' || tagName == 'div';
  }
  
  static bool _isExerciseText(String text) {
    if (text.length < 5) return false;
    
    // Common exercise keywords
    final exerciseKeywords = [
      'press', 'squat', 'deadlift', 'curl', 'row', 'pull', 'push',
      'lunge', 'raise', 'dip', 'fly', 'extension', 'crunch', 'plank',
      'bench', 'dumbbell', 'barbell', 'machine', 'cable'
    ];
    
    final lowerText = text.toLowerCase();
    return exerciseKeywords.any((keyword) => lowerText.contains(keyword));
  }
  
  static Map<String, List<Map<String, dynamic>>> _extractListBasedWorkout(Document document) {
    final data = <String, List<Map<String, dynamic>>>{};
    
    // Look for lists (ul, ol) that might contain exercises
    final lists = document.querySelectorAll('ul, ol');
    
    for (final list in lists) {
      final listItems = list.querySelectorAll('li');
      final exercises = <Map<String, dynamic>>[];
      
      for (final item in listItems) {
        final text = item.text?.trim() ?? '';
        if (text.isNotEmpty && _isExerciseText(text)) {
          final category = _classifyExercise(text);
          exercises.add({
            'exercise': text,
            'category': category,
          });
        }
      }
      
      if (exercises.isNotEmpty) {
        // Try to find a heading before this list
        Element? previous = list.previousElementSibling;
        String sectionName = 'Workout';
        
        while (previous != null) {
          final tagName = previous.localName?.toLowerCase() ?? '';
          if (tagName.startsWith('h') && int.tryParse(tagName.substring(1)) != null) {
            final headingText = previous.text?.trim() ?? '';
            if (headingText.isNotEmpty) {
              sectionName = _normalizeSectionName(headingText);
              break;
            }
          }
          previous = previous.previousElementSibling;
        }
        
        data[sectionName] = exercises;
      }
    }
    
    // If no structured lists found, look for paragraphs with exercise patterns
    if (data.isEmpty) {
      final paragraphs = document.querySelectorAll('p');
      final exercises = <Map<String, dynamic>>[];
      
      for (final p in paragraphs) {
        final text = p.text?.trim() ?? '';
        if (text.isNotEmpty && _isExerciseText(text)) {
          final category = _classifyExercise(text);
          exercises.add({
            'exercise': text,
            'category': category,
          });
        }
      }
      
      if (exercises.isNotEmpty) {
        data['Workout'] = exercises;
      }
    }
    
    return data;
  }
  
  static Map<String, dynamic> _convertToUniversalFormat(Map<String, List<Map<String, dynamic>>> workoutData, String extractionMethod) {
    final weeklyWorkout = <String, dynamic>{};
    final allExercises = <Map<String, dynamic>>[];
    int totalSets = 0;
    
    // Convert workout data to structured format (works for all extraction methods)
    for (final entry in workoutData.entries) {
      final dayName = entry.key;
      final exercises = entry.value;
      
      final structuredExercises = <Map<String, dynamic>>[];
      for (final exercise in exercises) {
        final exerciseName = exercise['exercise'] as String;
        final category = exercise['category'] as String;
        
        // Parse exercise details
        final parsedExercise = _parseExerciseFromTextImproved(exerciseName);
        parsedExercise['category'] = category;
        
        if (parsedExercise['name'].toString().isNotEmpty) {
          structuredExercises.add(parsedExercise);
        }
      }
      
      if (structuredExercises.isNotEmpty) {
        final daySets = structuredExercises.fold<int>(0, (sum, e) => sum + ((e['sets'] as int?) ?? 0));
        weeklyWorkout[dayName] = {
          'day': dayName,
          'exercises': structuredExercises,
          'totalSets': daySets,
          'duration': _estimateWorkoutDuration(structuredExercises),
        };
        
        allExercises.addAll(structuredExercises);
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

  static Map<String, List<Map<String, dynamic>>> _convertDefaultToWorkoutData(Map<String, dynamic> defaultData) {
    final workoutData = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in defaultData.entries) {
      if (entry.key == 'allExercises') continue;
      if (entry.key == 'totalSets') continue;
      if (entry.key == 'totalDays') continue;
      
      final dayData = entry.value as Map<String, dynamic>;
      final exercises = dayData['exercises'] as List<dynamic>;
      
      final convertedExercises = <Map<String, dynamic>>[];
      for (final exercise in exercises) {
        final exerciseMap = exercise as Map<String, dynamic>;
        convertedExercises.add({
          'exercise': exerciseMap['name'] as String,
          'category': _classifyExercise(exerciseMap['name'] as String),
        });
      }
      
      workoutData[entry.key] = convertedExercises;
    }
    
    return workoutData;
  }
  
  static String _determineCategoryUniversal(String title, Map<String, List<Map<String, dynamic>>> workoutData) {
    final titleLower = title.toLowerCase();
    
    // Check title first for specific workout types
    if (titleLower.contains('thor') || titleLower.contains('god')) {
      return 'Full Body';
    }
    if (titleLower.contains('chest') || titleLower.contains('push')) {
      return 'Chest';
    }
    if (titleLower.contains('back') || titleLower.contains('pull')) {
      return 'Back';
    }
    if (titleLower.contains('leg') || titleLower.contains('squat')) {
      return 'Legs';
    }
    if (titleLower.contains('arm') || titleLower.contains('bicep') || titleLower.contains('tricep')) {
      return 'Arms';
    }
    if (titleLower.contains('shoulder') || titleLower.contains('deltoid')) {
      return 'Shoulders';
    }
    if (titleLower.contains('abs') || titleLower.contains('core')) {
      return 'Abs';
    }
    
    // Count exercises by category across all days
    final categoryCounts = <String, int>{};
    
    for (final dayExercises in workoutData.values) {
      for (final exercise in dayExercises) {
        final category = exercise['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    
    // Find dominant category
    String dominantCategory = 'Full Body';
    int maxCount = 0;
    
    for (final entry in categoryCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
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
      default:
        return 'Full Body';
    }
  }
} 