import 'package:flutter/material.dart';
import 'services/debug_api.dart';

/// Quick debug helper for bet detection issues
class DebugHelper {
  
  /// Call this method to run all debug checks
  static Future<void> runBetDebugChecks() async {
    print('\n🔍 ===== STARTING BET DEBUG SESSION =====');
    
    // 1. Check user authentication
    print('\n1️⃣ Checking user authentication...');
    await DebugApiService.debugUserAuthentication();
    
    // 2. Check raw API response
    print('\n2️⃣ Checking raw API response...');
    await DebugApiService.debugRacesApiResponse();
    
    // 3. Run full bet detection analysis
    print('\n3️⃣ Running bet detection analysis...');
    await DebugApiService.debugBetDetection();
    
    print('\n🏁 ===== DEBUG SESSION COMPLETE =====\n');
  }
  
  /// Debug a specific race (call this with your bet's season/round)
  static Future<void> debugSpecificRace(String season, String round) async {
    print('\n🎯 ===== DEBUGGING SPECIFIC RACE =====');
    print('Season: $season, Round: $round');
    
    await DebugApiService.debugSpecificRace(season, round);
    
    print('🏁 ===== SPECIFIC RACE DEBUG COMPLETE =====\n');
  }
}

/// Debug Button Widget - Add this temporarily to your home screen
class DebugButton extends StatelessWidget {
  const DebugButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        // Run debug checks
        await DebugHelper.runBetDebugChecks();
        
        // Also debug specific race if you know the details
        // Replace "2025" and "1" with your actual bet's season/round
        await DebugHelper.debugSpecificRace("2025", "1");
        
        // Show completion message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debug complete! Check console/logs for results.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      child: const Icon(Icons.bug_report),
      backgroundColor: Colors.red,
      tooltip: 'Debug Bet Detection',
    );
  }
}