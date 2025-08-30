import 'package:flutter/material.dart';
import 'dart:io';

class NetworkPermissionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.wifi,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Network Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'To import workouts from the web, this app needs network access. The app will use default workout data if network access is not available.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showNetworkOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Try Anyway',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNetworkOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Options'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you\'re on a simulator:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Network access may be limited'),
            Text('• The app will use default workout data'),
            Text('• You can still test all features'),
            SizedBox(height: 12),
            Text(
              'If you\'re on a real device:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Go to Settings > Privacy & Security'),
            Text('• Tap "Local Network"'),
            Text('• Enable "Fitness First"'),
            SizedBox(height: 12),
            Text(
              'The app will work either way! 🎉',
              style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF10B981)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
