// lib/pages/dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'auth_page.dart';
import 'profile_setup.dart';
import 'meal_plan_page.dart';
import 'food_search_page.dart';
import '../theme/theme_controller.dart';
import 'reminders_page.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String userName = "User";
  Map<String, dynamic>? userProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection("profiles").doc(currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          userName = (data['name']?.toString().trim().isNotEmpty == true)
              ? data['name']
              : (currentUser!.displayName ?? "User");

          final int age = (data["age"] is int) ? data["age"] : int.tryParse(data["age"]?.toString() ?? "") ?? 25;
          final double weight = (data["weight"] is num) ? (data["weight"] as num).toDouble() : double.tryParse(data["weight"]?.toString() ?? "") ?? 70.0;
          final double height = (data["height"] is num) ? (data["height"] as num).toDouble() : double.tryParse(data["height"]?.toString() ?? "") ?? 170.0;
          final String gender = (data["gender"]?.toString().toLowerCase() ?? "male");
          final String activityLevel = (data["activityLevel"]?.toString().toLowerCase() ?? data["activity_level"]?.toString().toLowerCase() ?? "moderate");
          final String goal = (data["goal"]?.toString() ?? "weight-loss");

          userProfile = {
            "age": age,
            "weight": weight,
            "height": height,
            "gender": gender,
            "activity_level": activityLevel,
            "goal": goal,
          };
          _loading = false;
        });

        try {
          await ReminderService().resyncAllForUser(currentUser!.uid);
        } catch (e) {}
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
    }
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap, int i, {Color? accent}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withOpacity(.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: accent != null ? LinearGradient(colors: [accent.withOpacity(.95), accent.withOpacity(.7)]) : AppTheme.brandGradient(),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 10, offset: const Offset(0, 6))],
              ),
              child: Center(child: Icon(icon, size: 28, color: Colors.white)),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ).animate(delay: (80 * i).ms).fadeIn(duration: 260.ms).moveY(begin: 10, end: 0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeCtrl = Provider.of<ThemeController>(context, listen: false);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Satwik Diet", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: "Toggle theme", icon: const Icon(Icons.dark_mode_outlined), onPressed: themeCtrl.toggle),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient(),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  // left: greeting + stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome,", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(userName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _miniStat("${userProfile?['weight']?.toStringAsFixed(0) ?? '—'} kg", "Weight"),
                          const SizedBox(width: 8),
                          _miniStat("${userProfile?['age'] ?? '—'}", "Age"),
                          const SizedBox(width: 8),
                          _miniStat("${userProfile?['goal'] == 'weight_loss' ? 'Weight' : 'Diabetic'}", "Goal"),
                        ])
                      ],
                    ),
                  ),
                  // avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.12)),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: currentUser?.photoURL != null
                          ? Image.network(currentUser!.photoURL!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/OG_logo.png', fit: BoxFit.cover))
                          : Image.asset('assets/OG_logo.png', fit: BoxFit.cover),
                    ),
                  )
                ],
              ),
            ),

            // body grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.02,
                  children: [
                    _tile("My Plan", Icons.calendar_month, () {
                      if (userProfile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile not loaded yet")));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlanPage(userProfile: userProfile!)));
                    }, 0, accent: Colors.deepOrangeAccent),
                    _tile("Food Explorer", Icons.search, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchPage()));
                    }, 1, accent: Colors.green),
                    _tile("Reminders", Icons.alarm, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersPage()));
                    }, 2, accent: Colors.purple),
                    _tile("Profile", Icons.person, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSetupPage(userId: currentUser?.uid ?? "")));
                    }, 3, accent: Colors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
