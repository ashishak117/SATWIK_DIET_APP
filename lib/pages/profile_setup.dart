// lib/pages/profile_setup.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import 'dashboard.dart';
import '../theme/app_theme.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userId;

  const ProfileSetupPage({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _gender = "male";
  String _activityLevel = "sedentary";
  String _goal = "weight-loss";

  bool _isEditing = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("profiles")
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _ageController.text = data["age"]?.toString() ?? "";
          _heightController.text = data["height"]?.toString() ?? "";
          _weightController.text = data["weight"]?.toString() ?? "";
          _gender = data["gender"] ?? "male";
          _activityLevel = data["activity_level"] ?? "sedentary";
          _goal = (data["goal"] ?? "weight-loss").toString().replaceAll("_", "-");
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final int parsedAge = int.tryParse(_ageController.text) ?? 0;
    final double parsedWeight = double.tryParse(_weightController.text) ?? 0.0;
    final double parsedHeight = double.tryParse(_heightController.text) ?? 0.0;

    try {
      await FirebaseFirestore.instance.collection("profiles").doc(widget.userId).set({
        "age": parsedAge,
        "height": parsedHeight,
        "weight": parsedWeight,
        "gender": _gender,
        "activity_level": _activityLevel,
        "goal": _goal.replaceAll("_", "-"),
      });

      final ApiService apiService = ApiService();
      final newPlan = await apiService.generatePlan(
        userId: widget.userId,
        age: parsedAge,
        weight: parsedWeight,
        height: parsedHeight,
        gender: _gender,
        activityLevel: _activityLevel,
        goal: _goal,
      );

      if (newPlan["plan"] != null) {
        await FirebaseFirestore.instance
            .collection("meal_plans")
            .doc(widget.userId)
            .set({
          "plan": List<Map<String, dynamic>>.from(newPlan["plan"]),
          "needs": newPlan["needs"] ?? {},
          "updatedAt": DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile & Meal Plan updated")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(labelText: "Age"),
                          keyboardType: TextInputType.number,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Enter your age";
                            final age = int.tryParse(value);
                            if (age == null) return "Age must be a number";
                            if (age < 5 || age > 120) return "Enter a valid age (5–120)";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(labelText: "Height (cm)"),
                          keyboardType: TextInputType.number,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Enter your height";
                            final height = double.tryParse(value);
                            if (height == null) return "Height must be a number";
                            if (height < 50 || height > 300) return "Enter a valid height (50–300 cm)";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(labelText: "Weight (kg)"),
                          keyboardType: TextInputType.number,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Enter your weight";
                            final weight = double.tryParse(value);
                            if (weight == null) return "Weight must be a number";
                            if (weight < 10 || weight > 500) return "Enter a valid weight (10–500 kg)";
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: const InputDecoration(labelText: "Gender"),
                          items: const [
                            DropdownMenuItem(value: "male", child: Text("Male")),
                            DropdownMenuItem(value: "female", child: Text("Female")),
                          ],
                          onChanged: _isEditing ? (val) => setState(() => _gender = val!) : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _activityLevel,
                          decoration: const InputDecoration(labelText: "Activity Level"),
                          items: const [
                            DropdownMenuItem(value: "sedentary", child: Text("Sedentary")),
                            DropdownMenuItem(value: "moderate", child: Text("Moderate")),
                            DropdownMenuItem(value: "active", child: Text("Active")),
                          ],
                          onChanged: _isEditing ? (val) => setState(() => _activityLevel = val!) : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _goal,
                          decoration: const InputDecoration(labelText: "Goal"),
                          items: const [
                            DropdownMenuItem(value: "weight-loss", child: Text("Weight Loss")),
                            DropdownMenuItem(value: "strict-diabetes-control", child: Text("Strict Diabetes Control")),
                          ],
                          onChanged: _isEditing ? (val) => setState(() => _goal = val!) : null,
                        ),
                        const SizedBox(height: 22),

                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Text("Save", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                  ),
                                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "This information helps Satwik Diet generate a personalized 30-day meal plan.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
