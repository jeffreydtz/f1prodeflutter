import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'utils/logger.dart';

/// Quick diagnostic for the specific bet detection issue
class QuickDebug {
  
  static Future<void> diagnoseBetIssue() async {
    final apiService = ApiService();
    
    Logger.info('\n🔍 QUICK DIAGNOSTIC FOR BET DETECTION ISSUE');
    Logger.info('==========================================');
    
    // 1. Check current user
    final currentUser = apiService.getCurrentUser();
    Logger.info('\n1️⃣ CURRENT USER CHECK:');
    if (currentUser != null) {
      Logger.info('   ✅ User ID: ${currentUser.id}');
      Logger.info('   ✅ Username: ${currentUser.username}');
      Logger.info('   ✅ User ID Type: ${currentUser.id.runtimeType}');
    } else {
      Logger.error('   ❌ No current user found!');
      return;
    }
    
    // 2. Check if user ID matches expected
    Logger.info('\n2️⃣ USER ID MATCHING:');
    if (currentUser.id == '1') {
      Logger.info('   ✅ User ID matches Supabase (1)');
    } else {
      Logger.warning('   ❌ User ID mismatch! Flutter: "${currentUser.id}" vs Supabase: "1"');
    }
    
    // 3. Get user's bet results
    Logger.info('\n3️⃣ USER BET RESULTS:');
    try {
      final betResults = await apiService.getUserBetResults();
      Logger.info('   📊 Found ${betResults.length} bet results');
      
      for (int i = 0; i < betResults.length && i < 3; i++) {
        final bet = betResults[i];
        Logger.info('   🏁 Bet ${i + 1}:');
        Logger.info('      - Race: ${bet.raceName}');
        Logger.info('      - Season: "${bet.season}" (${bet.season.runtimeType})');
        Logger.info('      - Round: "${bet.round}" (${bet.round.runtimeType})');
        Logger.info('      - User ID: "${bet.userId}" (${bet.userId.runtimeType})');
      }
    } catch (e) {
      Logger.error('   ❌ Error getting bet results: $e');
    }
    
    // 4. Get races and check first few
    Logger.info('\n4️⃣ RACE DATA CHECK:');
    try {
      final races = await apiService.getRaces();
      Logger.info('   📊 Found ${races.length} races');
      
      for (int i = 0; i < races.length && i < 5; i++) {
        final race = races[i];
        Logger.info('   🏁 Race ${i + 1}:');
        Logger.info('      - Name: ${race.name}');
        Logger.info('      - Season: "${race.season}" (${race.season.runtimeType})');
        Logger.info('      - Round: "${race.round}" (${race.round.runtimeType})');
        Logger.info('      - Has Bet: ${race.hasBet}');
      }
    } catch (e) {
      Logger.error('   ❌ Error getting races: $e');
    }
    
    // 5. Manual comparison
    Logger.info('\n5️⃣ MANUAL COMPARISON:');
    try {
      final betResults = await apiService.getUserBetResults();
      final races = await apiService.getRaces();
      
      if (betResults.isNotEmpty && races.isNotEmpty) {
        final firstBet = betResults.first;
        Logger.info('   🔍 Looking for race matching bet:');
        Logger.info('      - Bet Season: "${firstBet.season}"');
        Logger.info('      - Bet Round: "${firstBet.round}"');
        
        final matchingRaces = races.where((race) => 
          race.season == firstBet.season && race.round == firstBet.round
        ).toList();
        
        Logger.info('   🎯 Found ${matchingRaces.length} matching races');
        
        if (matchingRaces.isNotEmpty) {
          final race = matchingRaces.first;
          Logger.info('      - Race: ${race.name}');
          Logger.info('      - Has Bet: ${race.hasBet}');
          
          if (!race.hasBet) {
            Logger.error('   ❌ PROBLEM FOUND: Race should have bet but hasBet=false');
            Logger.error('   🔧 This indicates a backend issue!');
          } else {
            Logger.info('   ✅ Race correctly shows hasBet=true');
          }
        }
      }
    } catch (e) {
      Logger.error('   ❌ Error in manual comparison: $e');
    }
    
    Logger.info('\n🏁 DIAGNOSTIC COMPLETE');
    Logger.info('==========================================\n');
  }
}

/// Extension to quickly add debug to any widget
extension DebugExtension on StatefulWidget {
  void runQuickDebug() {
    QuickDebug.diagnoseBetIssue();
  }
}