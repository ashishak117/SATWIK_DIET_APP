// lib/pages/food_search_page.dart
// Improved, responsive & decorative Food Explorer page
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class FoodSearchPage extends StatefulWidget {
  const FoodSearchPage({super.key});

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<dynamic> _results = [];
  bool _loading = false;
  bool _firstOpen = true;

  bool _diabetesOnly = false;
  bool _weightOnly = false;

  Future<void> _refresh() async => _search();

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _firstOpen = false;
    });
    // Close keyboard gracefully
    _focus.unfocus();
    try {
      final data = await _api.searchFoodLocal(
        q,
        limit: 30,
        diabetesOnly: _diabetesOnly,
        weightOnly: _weightOnly,
      );
      if (!mounted) return;
      setState(() => _results = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  LinearGradient get _headerGradient => AppTheme.brandGradient();

  BoxDecoration get _glass => BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withOpacity(0.88),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline.withOpacity(.10),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      )
    ],
  );

  Widget _chip(String text, {IconData? icon, required bool active, VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    final bg = active ? cs.primaryContainer : cs.surfaceVariant;
    final fg = active ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16, color: fg),
            if (icon != null) const SizedBox(width: 6),
            Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: fg, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(dynamic item, int index) {
    final name = (item['name'] ?? "").toString();
    final ayur = item['ayurveda'] ?? {};
    final rasa = ayur['rasa'] ?? '—';
    final virya = ayur['virya'] ?? '—';
    final vipaka = ayur['vipaka'] ?? '—';
    final diab = ayur['diabetes_safe'] == true;
    final weight = ayur['weight_loss_friendly'] == true;

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading avatar circle with gradient ring — limited size so it won't overflow
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _headerGradient,
                ),
                child: Center(
                  child: Text(
                    (name.isNotEmpty ? name[0] : "?").toUpperCase(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Main content: flexible so long text doesn't overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with ellipsis and a subtle wrap fallback
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // chevron
                        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Small metadata row (pills)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniPill("Rasa: $rasa"),
                        _miniPill("Virya: $virya"),
                        _miniPill("Vipaka: $vipaka"),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Health badges row - scrollable horizontally on extreme small widths
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _healthBadge(ok: diab, onTrue: "Diabetes-safe", onFalse: "Not safe"),
                          const SizedBox(width: 8),
                          _healthBadge(ok: weight, onTrue: "Weight-loss friendly", onFalse: "Not ideal"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).fadeIn(duration: 250.ms).moveY(begin: 12, end: 0, curve: Curves.easeOut);
  }

  Widget _miniPill(String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
    );
  }

  Widget _healthBadge({required bool ok, required String onTrue, required String onFalse}) {
    final cs = Theme.of(context).colorScheme;
    final bg = ok ? Colors.green.withOpacity(.14) : Colors.red.withOpacity(.14);
    final fg = ok ? Colors.green.shade800 : Colors.red.shade800;
    final ic = ok ? Icons.check_circle : Icons.cancel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(ok ? onTrue : onFalse,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }

  void _showDetails(dynamic item) {
    final name = item['name'] ?? "";
    final ayur = item['ayurveda'] ?? {};
    final rasa = ayur['rasa'] ?? '—';
    final virya = ayur['virya'] ?? '—';
    final vipaka = ayur['vipaka'] ?? '—';
    final dosha = ayur['dosha_balance'] ?? '—';
    final benefits = ayur['ayurvedic_benefits'] ?? '—';
    final diab = ayur['diabetes_safe'] == true;
    final weight = ayur['weight_loss_friendly'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 56,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: cs.outline.withOpacity(.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(name,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniPill("Rasa: $rasa"),
                      _miniPill("Virya: $virya"),
                      _miniPill("Vipaka: $vipaka"),
                      _miniPill("Dosha: $dosha"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _healthBadge(ok: diab, onTrue: "Diabetes-safe", onFalse: "Not safe"),
                      _healthBadge(ok: weight, onTrue: "Weight-loss friendly", onFalse: "Not ideal"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cs.surfaceVariant.withOpacity(.6), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Ayurvedic Benefits", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        benefits.toString(),
                        style: GoogleFonts.inter(height: 1.4, color: cs.onSurfaceVariant),
                        textAlign: TextAlign.start,
                        softWrap: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close), label: const Text("Close"))),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Food Explorer", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final height = constraints.maxHeight;
          // responsive header height: min(220, 34% of available height)
          final headerH = mathMin(220, (height * 0.34).clamp(140, 220));
          return Column(
            children: [
              // Hero header (responsive)
              Container(
                height: headerH,
                width: double.infinity,
                decoration: BoxDecoration(gradient: _headerGradient),
                child: Stack(
                  children: [
                    // decorative circles (kept small & positioned so they never overflow)
                    Positioned(top: -headerH * 0.15, right: -headerH * 0.07, child: Container(width: headerH * 0.6, height: headerH * 0.6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.12)))),
                    Positioned(bottom: -headerH * 0.18, left: -headerH * 0.06, child: Container(width: headerH * 0.45, height: headerH * 0.45, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.10)))),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 980),
                          child: Container(
                            decoration: _glass,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: cs.primary),
                                const SizedBox(width: 8),
                                // TextField inside Flexible so it shrinks gracefully on small screens
                                Flexible(
                                  child: TextField(
                                    focusNode: _focus,
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: "Search foods (e.g., bitter gourd, tulsi, jeera)",
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.9)),
                                    ),
                                    onSubmitted: (_) => _search(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 72, maxWidth: 120),
                                  child: ElevatedButton(
                                    onPressed: _search,
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                                    child: const Text("Search"),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).moveY(begin: 10, end: 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filters row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip("Diabetes-safe", icon: Icons.bloodtype, active: _diabetesOnly, onTap: () {
                        setState(() => _diabetesOnly = !_diabetesOnly);
                        _search();
                      }),
                      _chip("Weight-loss friendly", icon: Icons.monitor_weight_outlined, active: _weightOnly, onTap: () {
                        setState(() => _weightOnly = !_weightOnly);
                        _search();
                      }),
                      SizedBox(
                        height: 40,
                        child: IconButton(tooltip: "Refresh", onPressed: _refresh, icon: const Icon(Icons.refresh)),
                      ),
                    ],
                  ),
                ),
              ),

              // Results
              Expanded(
                child: _loading
                    ? const _SkeletonList()
                    : _firstOpen
                    ? _EmptyState(
                  onExplore: () {
                    _controller.text = "bitter gourd";
                    _search();
                  },
                )
                    : RefreshIndicator(
                  onRefresh: _refresh,
                  child: LayoutBuilder(builder: (ctx, box) {
                    // Wrap list in SafeArea / Padding so long lists and keyboard don't cause overflow
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24, top: 6),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _resultCard(_results[i], i),
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // helper: small math min without importing dart:math explicitly
  double mathMin(double a, double b) => a < b ? a : b;
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20)),
        height: 96,
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(milliseconds: 1200), color: Colors.white.withOpacity(.12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_rounded, size: 72, color: cs.primary),
          const SizedBox(height: 12),
          Text("Discover Ayurvedic wisdom", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            "Search any food to view rasa, virya, vipaka, dosha balance, and whether it's diabetes-safe or weight-loss friendly.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onExplore, icon: const Icon(Icons.explore), label: const Text("Try 'bitter gourd'")),
        ]),
      ),
    );
  }
}
