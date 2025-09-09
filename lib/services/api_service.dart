// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Your Render base URL
  static const String baseUrl = "https://swatik-diet-app.onrender.com";

  // --------------------
  // Generate Meal Plan (JSON)
  // --------------------
  Future<Map<String, dynamic>> generatePlan({
    required String userId,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    final normalizedGoal = goal.replaceAll("-", "_");

    final url = Uri.parse("$baseUrl/plan");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "age": age,
        "weight": weight,
        "height": height,
        "gender": gender,
        "activity_level": activityLevel,
        "goal": normalizedGoal,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch plan: ${response.statusCode} ${response.body}");
    }
  }

  // --------------------
  // Download CSV
  // --------------------
  Future<String> downloadPlanCsv({
    required String userId,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    final normalizedGoal = goal.replaceAll("-", "_");

    final url = Uri.parse("$baseUrl/plan/csv");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "age": age,
        "weight": weight,
        "height": height,
        "gender": gender,
        "activity_level": activityLevel,
        "goal": normalizedGoal,
      }),
    );

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/plan.csv";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw Exception("Download failed: ${response.statusCode} ${response.body}");
    }
  }

  // --------------------
  // Food Explorer (Ayurveda JSON-only)
  // --------------------
  Future<List<dynamic>> searchFoodLocal(
      String query, {
        int limit = 20,
        bool diabetesOnly = false,
        bool weightOnly = false,
      }) async {
    final url = Uri.parse(
      "$baseUrl/api/ayur/search"
          "?q=${Uri.encodeComponent(query)}"
          "&limit=$limit"
          "&diabetes_only=$diabetesOnly"
          "&weight_only=$weightOnly",
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception("Search failed: ${resp.statusCode} ${resp.body}");
    }
    final Map<String, dynamic> data = jsonDecode(resp.body);
    return data["results"] ?? [];
  }
}
