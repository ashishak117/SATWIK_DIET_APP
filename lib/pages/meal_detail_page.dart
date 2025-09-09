// lib/pages/meal_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class MealDetailPage extends StatelessWidget {
  final Map<String, dynamic> meal;
  const MealDetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final String foodName = meal["Foods"]?.toString() ?? "Unknown Food";
    final String mealLabel = meal["Meal"]?.toString() ?? "";

    final double calories = (meal["Calories"] is num) ? (meal["Calories"] as num).toDouble() : 0.0;
    final double protein = (meal["Protein (g)"] is num) ? (meal["Protein (g)"] as num).toDouble() : 0.0;
    final double carbs = (meal["Carbs (g)"] is num) ? (meal["Carbs (g)"] as num).toDouble() : 0.0;
    final double fat = (meal["Fat (g)"] is num) ? (meal["Fat (g)"] as num).toDouble() : 0.0;

    // Avoid divide-by-zero
    final double macroSum = (protein + carbs + fat) > 0 ? (protein + carbs + fat) : 1.0;
    final double pPct = protein / macroSum;
    final double cPct = carbs / macroSum;
    final double fPct = fat / macroSum;

    final ayur = meal['ayurveda'] as Map<String, dynamic>?;

    // Responsive stat card (returns a widget not forcing Expanded)
    Widget _statCard(String label, String value, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) Icon(icon, size: 16, color: cs.primary),
              if (icon != null) const SizedBox(width: 8),
              Flexible(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant))),
            ]),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    // Bar widget for macros (responsive)
    Widget _macroBar(String label, double pct, Color color, String valueText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(valueText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final fullW = constraints.maxWidth;
            final targetW = fullW * pct.clamp(0.0, 1.0);
            return Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  width: targetW,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withOpacity(.95), color.withOpacity(.7)]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                ),
              ],
            );
          }),
        ],
      );
    }

    // Info chip
    Widget _infoChip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withOpacity(.06)),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(mealLabel.isNotEmpty ? mealLabel : "Meal Details", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: "Share",
            onPressed: () {
              final text = "$foodName — ${calories.toStringAsFixed(0)} kcal\nShared from Satwik Diet";
              Share.share(text);
            },
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Use SafeArea + SingleChildScrollView to avoid overflow and make layout flexible
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card (responsive)
              LayoutBuilder(builder: (ctx, box) {
                final maxW = box.maxWidth;
                final avatarSize = maxW < 360 ? 72.0 : 86.0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary.withOpacity(.95), cs.primary.withOpacity(.8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // avatar / icon - size scales on narrow widths
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 8, offset: const Offset(0, 6))],
                          border: Border.all(color: Colors.white.withOpacity(.06)),
                        ),
                        child: Center(
                          child: Text(
                            (foodName.isNotEmpty ? foodName[0].toUpperCase() : "?"),
                            style: GoogleFonts.inter(fontSize: avatarSize * 0.36, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // title + quick stats - flexible so it wraps on narrow phones
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // allow multi-line title so full name is visible
                            Text(foodName,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                softWrap: true),
                            const SizedBox(height: 6),
                            // show full description (no maxLines) so user can read entire meal details
                            Text(
                              meal["Description"]?.toString() ?? "Nutritious & balanced.",
                              style: GoogleFonts.inter(color: Colors.white70),
                              softWrap: true,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department, size: 14, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text("${calories.toStringAsFixed(0)} kcal", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.restaurant_menu, size: 14, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(mealLabel, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 18),

              // Stat cards area — adapt layout to width
              LayoutBuilder(builder: (ctx, box) {
                final w = box.maxWidth;
                final isNarrow = w < 520;
                if (isNarrow) {
                  // stack vertically
                  return Column(
                    children: [
                      _statCard("Calories", "${calories.toStringAsFixed(0)} kcal", icon: Icons.local_fire_department),
                      const SizedBox(height: 10),
                      _statCard("Protein", "${protein.toStringAsFixed(1)} g", icon: Icons.spa),
                      const SizedBox(height: 10),
                      _statCard("Carbs", "${carbs.toStringAsFixed(1)} g", icon: Icons.grain),
                    ],
                  );
                } else {
                  // show horizontally, with flexible widths
                  return Row(
                    children: [
                      Flexible(child: _statCard("Calories", "${calories.toStringAsFixed(0)} kcal", icon: Icons.local_fire_department)),
                      const SizedBox(width: 10),
                      Flexible(child: _statCard("Protein", "${protein.toStringAsFixed(1)} g", icon: Icons.spa)),
                      const SizedBox(width: 10),
                      Flexible(child: _statCard("Carbs", "${carbs.toStringAsFixed(1)} g", icon: Icons.grain)),
                    ],
                  );
                }
              }),

              const SizedBox(height: 18),

              // Macronutrient breakdown header
              Row(
                children: [
                  Text("Macronutrients", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text("${(pPct * 100).toInt()} / ${(cPct * 100).toInt()} / ${(fPct * 100).toInt()}",
                      style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                ],
              ),

              const SizedBox(height: 12),

              // Macro bars (each uses LayoutBuilder internally so it's safe)
              _macroBar("Protein", pPct, Colors.green.shade600, "${protein.toStringAsFixed(1)} g"),
              const SizedBox(height: 12),
              _macroBar("Carbs", cPct, Colors.orange.shade700, "${carbs.toStringAsFixed(1)} g"),
              const SizedBox(height: 12),
              _macroBar("Fat", fPct, Colors.purple.shade600, "${fat.toStringAsFixed(1)} g"),

              const SizedBox(height: 20),

              // Ayurvedic / Details section (if present)
              if (ayur != null) ...[
                Text("Ayurvedic Info", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (ayur['rasa'] != null) _infoChip("Rasa: ${ayur['rasa']}"),
                    if (ayur['virya'] != null) _infoChip("Virya: ${ayur['virya']}"),
                    if (ayur['vipaka'] != null) _infoChip("Vipaka: ${ayur['vipaka']}"),
                    if (ayur['dosha_balance'] != null) _infoChip("Dosha: ${ayur['dosha_balance']}"),
                    if (ayur['diabetes_safe'] != null) _infoChip(ayur['diabetes_safe'] == true ? "Diabetes-safe" : "Not diabetes-safe"),
                    if (ayur['weight_loss_friendly'] != null) _infoChip(ayur['weight_loss_friendly'] == true ? "Weight-loss friendly" : "Not ideal for weight-loss"),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Ingredients / Notes (if present) - show full text (no truncation)
              if ((meal['Notes'] ?? meal['Ingredients'] ?? '').toString().trim().isNotEmpty) ...[
                Text("Notes", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline.withOpacity(.08))),
                  child: Text((meal['Notes'] ?? meal['Ingredients'] ?? '').toString(), style: GoogleFonts.inter(color: cs.onSurfaceVariant, height: 1.4)),
                ),
                const SizedBox(height: 18),
              ],

              // Actions (only Share button now, responsive)
              LayoutBuilder(builder: (ctx, box) {
                final narrow = box.maxWidth < 420;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final shareText = "$foodName • ${calories.toStringAsFixed(0)} kcal\nFrom Satwik Diet";
                          Share.share(shareText);
                        },
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text("Share"),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final shareText = "$foodName • ${calories.toStringAsFixed(0)} kcal\nFrom Satwik Diet";
                            Share.share(shareText);
                          },
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text("Share"),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  );
                }
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
