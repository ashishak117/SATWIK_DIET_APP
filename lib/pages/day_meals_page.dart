// lib/pages/day_meals_page.dart
import 'package:flutter/material.dart';
import 'meal_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

class DayMealsPage extends StatefulWidget {
  final int day;
  final List<Map<String, dynamic>> meals;

  const DayMealsPage({super.key, required this.day, required this.meals});

  @override
  State<DayMealsPage> createState() => _DayMealsPageState();
}

class _DayMealsPageState extends State<DayMealsPage> {
  // local favorites cache (ids not provided in model so using index-based keys)
  final Set<int> _favorites = {};

  String _normalizeMeal(dynamic v) {
    final s = v?.toString().toLowerCase().trim() ?? "";
    if (s.contains("breakfast")) return "Breakfast";
    if (s.contains("lunch")) return "Lunch";
    if (s.contains("snack")) return "Snack";
    if (s.contains("dinner")) return "Dinner";
    return "Other";
  }

  Map<String, List<Map<String, dynamic>>> _groupMeals(List<Map<String, dynamic>> meals) {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      "Breakfast": [],
      "Lunch": [],
      "Snack": [],
      "Dinner": [],
      "Other": [],
    };
    for (final m in meals) {
      grouped[_normalizeMeal(m["Meal"])]!.add(m);
    }
    return grouped;
  }

  Widget _macroChip(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(right: 6, top: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          if (icon != null) const SizedBox(width: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _shareMeal(Map<String, dynamic> meal) async {
    final food = meal['Foods']?.toString() ?? 'Meal';
    final kcal = (meal['Calories'] != null) ? meal['Calories'].toString() : 'N/A';
    final text = "$food — $kcal kcal\nShared from Satwik Diet";
    await Share.share(text);
  }

  Future<void> _shareDay(List<Map<String, dynamic>> meals) async {
    if (meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No meals to share for this day")));
      return;
    }
    final sb = StringBuffer();
    sb.writeln("Day ${widget.day} meal plan:");
    for (final m in meals) {
      final food = m['Foods']?.toString() ?? 'Meal';
      final kcal = (m['Calories'] != null) ? m['Calories'].toString() : 'N/A';
      sb.writeln("- $food • $kcal kcal");
    }
    await Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupMeals(widget.meals);
    final cs = Theme.of(context).colorScheme;

    // Flattened index counter for unique favorite keys (since meals may not have IDs)
    int _globalIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Day ${widget.day} Meals", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: widget.meals.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => _shareDay(widget.meals),
        icon: const Icon(Icons.share),
        label: const Text("Share day"),
      ).animate().fadeIn(delay: 120.ms).moveY(begin: 8, end: 0)
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: grouped.entries
            .where((e) => e.value.isNotEmpty)
            .toList()
            .asMap()
            .entries
            .map((sectionEntry) {
          final sectionIndex = sectionEntry.key;
          final entry = sectionEntry.value;
          final mealType = entry.key;
          final mealList = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header with gradient background and count badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient(),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 14, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Icon(
                      mealType == "Breakfast"
                          ? Icons.free_breakfast
                          : mealType == "Lunch"
                          ? Icons.lunch_dining
                          : mealType == "Dinner"
                          ? Icons.dinner_dining
                          : mealType == "Snack"
                          ? Icons.fastfood
                          : Icons.restaurant_menu,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(mealType, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                      child: Text("${mealList.length} item${mealList.length > 1 ? 's' : ''}", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ).animate(delay: (80 * sectionIndex).ms).fadeIn(duration: 320.ms).moveY(begin: 8, end: 0),

              // Meals in this section
              ...mealList.asMap().entries.map((me) {
                final localIdx = _globalIndex;
                _globalIndex++;
                final meal = me.value;
                final food = meal["Foods"]?.toString() ?? "Unnamed Meal";
                final kcal = (meal["Calories"] is num) ? (meal["Calories"] as num).toString() : (meal["Calories"]?.toString() ?? "N/A");
                final protein = (meal["Protein (g)"] is num) ? (meal["Protein (g)"] as num).toDouble() : 0.0;
                final carbs = (meal["Carbs (g)"] is num) ? (meal["Carbs (g)"] as num).toDouble() : 0.0;
                final fat = (meal["Fat (g)"] is num) ? (meal["Fat (g)"] as num).toDouble() : 0.0;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailPage(meal: meal)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            // Leading colored avatar
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.brandGradient(),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8, offset: const Offset(0, 6))],
                              ),
                              child: Center(
                                child: Text(
                                  (food.isNotEmpty ? food[0] : "?").toUpperCase(),
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title + macros (flexible)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(food,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'fav') {
                                            setState(() {
                                              if (_favorites.contains(localIdx)) {
                                                _favorites.remove(localIdx);
                                              } else {
                                                _favorites.add(localIdx);
                                              }
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_favorites.contains(localIdx) ? "Added to favorites" : "Removed from favorites")));
                                          } else if (v == 'share') {
                                            await _shareMeal(meal);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(value: 'fav', child: Row(children: [Icon(_favorites.contains(localIdx) ? Icons.favorite : Icons.favorite_border), const SizedBox(width: 8), Text(_favorites.contains(localIdx) ? "Unfavorite" : "Add to favorites")])),
                                          const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.ios_share_outlined), SizedBox(width: 8), Text("Share")])),
                                        ],
                                        child: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Macro chips row (wrap so it won't overflow)
                                  Wrap(
                                    runSpacing: 6,
                                    children: [
                                      _macroChip("kcal", "$kcal", icon: Icons.local_fire_department),
                                      if (protein > 0) _macroChip("protein", "${protein.toStringAsFixed(1)}g", icon: Icons.spa),
                                      if (carbs > 0) _macroChip("carbs", "${carbs.toStringAsFixed(1)}g", icon: Icons.grain),
                                      if (fat > 0) _macroChip("fat", "${fat.toStringAsFixed(1)}g", icon: Icons.opacity),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate(delay: (80 * me.key + 60).ms).fadeIn(duration: 260.ms).moveY(begin: 8, end: 0);
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }
}
