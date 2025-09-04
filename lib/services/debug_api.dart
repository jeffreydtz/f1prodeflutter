import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Debug utilities to help diagnose bet detection issues
class DebugApiService {
  static final ApiService _apiService = ApiService();
  static const String baseUrl = 'https://f1prodedjango.vercel.app/api';

  /// Debug user's bets and compare with race data
  static Future<void> debugBetDetection() async {
    try {
      Logger.info('[DEBUG] Starting bet detection analysis...');
      
      // 1. Get user's bets directly
      final betsResponse = await _apiService.getUserBetResults();
      Logger.info('[DEBUG] User has ${betsResponse.length} bets in total');
      
      for (final betResult in betsResponse) {
        Logger.info('[DEBUG] Bet found: season=${betResult.season}, round=${betResult.round}, race=${betResult.raceName}');
      }
      
      // 2. Get all races
      final races = await _apiService.getRaces();
      Logger.info('[DEBUG] Found ${races.length} races');
      
      // 3. Compare each race with user's bets
      for (final race in races.take(5)) { // Check first 5 races
        Logger.info('[DEBUG] Race: ${race.name} (season=${race.season}, round=${race.round}, hasBet=${race.hasBet})');
        
        // Check if this race should have a bet
        final shouldHaveBet = betsResponse.any((betResult) => 
          betResult.season == race.season && 
          betResult.round == race.round
        );
        
        if (shouldHaveBet && !race.hasBet) {
          Logger.error('[DEBUG] MISMATCH FOUND! Race ${race.name} should have bet but hasBet=false');
          Logger.error('[DEBUG] Race data: season=${race.season} (${race.season.runtimeType}), round=${race.round} (${race.round.runtimeType})');
          
          // Find the matching bet
          final matchingBet = betsResponse.firstWhere((betResult) => 
            betResult.season == race.season && 
            betResult.round == race.round
          );
          Logger.error('[DEBUG] Matching bet data: season=${matchingBet.season} (${matchingBet.season.runtimeType}), round=${matchingBet.round} (${matchingBet.round.runtimeType})');
        }
      }
      
    } catch (e) {
      Logger.error('[DEBUG] Error in bet detection analysis: $e');
    }
  }

  /// Make a direct API call to check backend response
  static Future<void> debugRacesApiResponse() async {
    try {
      Logger.info('[DEBUG] Making direct API call to races endpoint...');
      
      final accessToken = await _apiService.getStoredAccessToken();
      if (accessToken == null) {
        Logger.error('[DEBUG] No access token available');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/f1/races/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      Logger.info('[DEBUG] API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('[DEBUG] Raw API Response type: ${data.runtimeType}');
        
        if (data is Map<String, dynamic>) {
          Logger.info('[DEBUG] Response keys: ${data.keys.join(', ')}');
          
          if (data['races'] is List) {
            final races = data['races'] as List;
            Logger.info('[DEBUG] Found ${races.length} races in response');
            
            // Check first few races
            for (final raceData in races.take(3)) {
              Logger.info('[DEBUG] Raw race data: ${raceData.toString()}');
              Logger.info('[DEBUG] has_bet field: ${raceData['has_bet']} (${raceData['has_bet'].runtimeType})');
            }
          }
        } else if (data is List) {
          final races = data as List;
          Logger.info('[DEBUG] Direct list response with ${races.length} races');
          
          for (final raceData in races.take(3)) {
            Logger.info('[DEBUG] Raw race data: ${raceData.toString()}');
            Logger.info('[DEBUG] has_bet field: ${raceData['has_bet']} (${raceData['has_bet'].runtimeType})');
          }
        }
      } else {
        Logger.error('[DEBUG] API call failed with status: ${response.statusCode}');
        Logger.error('[DEBUG] Response body: ${response.body}');
      }
      
    } catch (e) {
      Logger.error('[DEBUG] Error in direct API call: $e');
    }
  }

  /// Debug specific race by season/round
  static Future<void> debugSpecificRace(String season, String round) async {
    try {
      Logger.info('[DEBUG] Debugging specific race: season=$season, round=$round');
      
      // Get all races and find the specific one
      final races = await _apiService.getRaces();
      final targetRace = races.where((race) => 
        race.season == season && race.round == round
      ).toList();
      
      if (targetRace.isEmpty) {
        Logger.error('[DEBUG] Race not found for season=$season, round=$round');
        return;
      }
      
      final race = targetRace.first;
      Logger.info('[DEBUG] Found race: ${race.name}');
      Logger.info('[DEBUG] Race hasBet: ${race.hasBet}');
      
      // Check user's bets for this race
      final bets = await _apiService.getUserBetResults();
      final matchingBets = bets.where((betResult) => 
        betResult.season == season && 
        betResult.round == round
      ).toList();
      
      Logger.info('[DEBUG] Found ${matchingBets.length} matching bets for this race');
      
      if (matchingBets.isNotEmpty && !race.hasBet) {
        Logger.error('[DEBUG] CRITICAL: Race should have bet but hasBet=false!');
        Logger.error('[DEBUG] This indicates a backend issue in the has_bet calculation');
      }
      
    } catch (e) {
      Logger.error('[DEBUG] Error debugging specific race: $e');
    }
  }

  /// Check if the issue is in the authentication
  static Future<void> debugUserAuthentication() async {
    try {
      Logger.info('[DEBUG] Checking user authentication...');
      
      final user = _apiService.getCurrentUser();
      if (user != null) {
        Logger.info('[DEBUG] Current user: ID=${user.id}, username=${user.username}');
      } else {
        Logger.error('[DEBUG] No current user found!');
      }
      
      // Try to get user profile
      final profile = await _apiService.getUserProfile();
      if (profile != null) {
        Logger.info('[DEBUG] User profile: ID=${profile.id}, username=${profile.username}');
      } else {
        Logger.error('[DEBUG] Could not load user profile!');
      }
      
    } catch (e) {
      Logger.error('[DEBUG] Error checking authentication: $e');
    }
  }
}