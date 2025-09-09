// lib/pages/meal_plan_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'day_meals_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MealPlanPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const MealPlanPage({super.key, required this.userProfile});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _plan = [];
  bool _loading = true;
  String? _csvPath;

  // Calendar state
  DateTime _focusedMonth = DateTime.now();
  int? _selectedDay; // day number in the currently focused month (1..N)
  // map keyed by yyyymmdd int -> list of meals for that exact calendar date
  Map<int, List<Map<String, dynamic>>> _mealsByDate = {};

  // actual start date of the plan (Day 1 => _planStart)
  DateTime? _planStart;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _fetchPlan();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // create a yyyymmdd integer key for a DateTime
  int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  Future<void> _fetchPlan() async {
    setState(() => _loading = true);
    try {
      if (currentUser == null) throw "User not logged in";

      final data = await _api_service_generateWrapper();
      final planList = (data["plan"] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Determine plan start date:
      DateTime start;
      if (data['start_date'] != null) {
        try {
          start = DateTime.parse(data['start_date'].toString());
        } catch (_) {
          start = DateTime.now();
        }
      } else if (data['startDate'] != null) {
        try {
          start = DateTime.parse(data['startDate'].toString());
        } catch (_) {
          start = DateTime.now();
        }
      } else if (data['createdAt'] != null) {
        try {
          start = DateTime.parse(data['createdAt'].toString());
        } catch (_) {
          start = DateTime.now();
        }
      } else {
        start = DateTime.now();
      }

      setState(() {
        _plan = planList;
        _planStart = DateTime(start.year, start.month, start.day);
        // show the month where plan starts
        _focusedMonth = DateTime(_planStart!.year, _planStart!.month);
        _loading = false;
      });

      _indexMealsByDate();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching plan: $e")));
      }
    }
  }

  // wrapper for API call to avoid long in-line code
  Future<Map<String, dynamic>> _api_service_generateWrapper() async {
    final data = await _apiService.generatePlan(
      userId: currentUser!.uid,
      age: widget.userProfile["age"] as int,
      weight: (widget.userProfile["weight"] as num).toDouble(),
      height: (widget.userProfile["height"] as num).toDouble(),
      gender: widget.userProfile["gender"] as String,
      activityLevel: widget.userProfile["activity_level"] as String,
      goal: widget.userProfile["goal"] as String,
    );
    return data;
  }

  void _indexMealsByDate() {
    final map = <int, List<Map<String, dynamic>>>{};
    if (_planStart == null) {
      setState(() => _mealsByDate = map);
      return;
    }

    for (final m in _plan) {
      final dnum = (m["Day"] is num) ? (m["Day"] as num).toInt() : int.tryParse(m["Day"]?.toString() ?? "");
      if (dnum == null) continue;
      final dt = _planStart!.add(Duration(days: dnum - 1));
      final key = _dateKey(dt);
      map.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(m));
    }

    setState(() => _mealsByDate = map);
  }

  Future<void> _downloadCsv() async {
    try {
      if (currentUser == null) throw "User not logged in";

      final path = await _api_service_downloadWrapper();
      setState(() => _csvPath = path);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Plan exported to $path")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
  }

  // helper wrapper so analyzer doesn't complain in the edited block
  Future<String> _api_service_downloadWrapper() async {
    final path = await _apiService.downloadPlanCsv(
      userId: currentUser!.uid,
      age: widget.userProfile["age"] as int,
      weight: (widget.userProfile["weight"] as num).toDouble(),
      height: (widget.userProfile["height"] as num).toDouble(),
      gender: widget.userProfile["gender"] as String,
      activityLevel: widget.userProfile["activity_level"] as String,
      goal: widget.userProfile["goal"] as String,
    );
    return path;
  }

  Future<void> _shareCsv() async {
    if (_csvPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please download CSV first")));
      return;
    }

    final file = File(_csvPath!);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: "📊 My 30-Day Meal Plan");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSV file not found")));
    }
  }

  // Utilities for calendar
  int _daysInMonth(DateTime month) {
    final next = (month.month < 12) ? DateTime(month.year, month.month + 1, 1) : DateTime(month.year + 1, 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  /// Weekday index where Monday=1 ... Sunday=7.
  int _firstDayWeekday(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    return first.weekday;
  }

  String _monthTitle(DateTime dt) {
    const months = [
      "January","February","March","April","May","June","July","August","September","October","November","December"
    ];
    return "${months[dt.month - 1]} ${dt.year}";
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDay = day;
    });
  }

  List<Widget> _buildWeekdayHeaders(TextStyle style) {
    final labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    return labels.map((l) => Center(child: Text(l, style: style))).toList();
  }

  DateTime _cellDateFor(int day) => DateTime(_focusedMonth.year, _focusedMonth.month, day);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final daysInCurrent = _daysInMonth(_focusedMonth);
    final firstWeekday = _firstDayWeekday(_focusedMonth); // 1..7 (Mon..Sun)
    final leadingEmpty = (firstWeekday - 1); // zero-based index for Mon start
    final totalCells = leadingEmpty + daysInCurrent;
    final rows = (totalCells / 7).ceil();

    // flatten calendar cells into list with null for empty leading cells
    final List<int?> cells = List<int?>.filled(rows * 7, null);
    for (int i = 0; i < daysInCurrent; i++) {
      final idx = leadingEmpty + i;
      cells[idx] = i + 1;
    }

    // selectedMeals for currently selected day
    List<Map<String, dynamic>> selectedMeals = [];
    if (_selectedDay != null) {
      final dt = _cellDateFor(_selectedDay!);
      final key = _dateKey(dt);
      selectedMeals = (_mealsByDate[key] ?? []).map((m) => Map<String, dynamic>.from(m)).toList();
    }

    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("30-Day Meal Plan"),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _downloadCsv),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareCsv),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Month header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth, tooltip: "Previous month"),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: Text(
                          _monthTitle(_focusedMonth),
                          key: ValueKey<String>(_monthTitle(_focusedMonth)),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth, tooltip: "Next month"),
                  ],
                ),
              ),
            ),

            // Weekday labels
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: _buildWeekdayHeaders(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700).copyWith(color: cs.onSurfaceVariant))
                      .map((w) => Expanded(child: w))
                      .toList(),
                ),
              ),
            ),

            // Calendar grid as SliverGrid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                    final day = cells[idx];
                    if (day == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }

                    final cellDate = _cellDateFor(day);
                    final key = _dateKey(cellDate);
                    final meals = _mealsByDate[key] ?? [];
                    final hasMeals = meals.isNotEmpty;
                    final cellDateOnly = DateTime(cellDate.year, cellDate.month, cellDate.day);
                    final todayDateOnly = DateTime(today.year, today.month, today.day);
                    final isPast = cellDateOnly.isBefore(todayDateOnly);
                    final isToday = cellDateOnly == todayDateOnly;
                    final isSelected = (_selectedDay == day && _focusedMonth.month == today.month && _focusedMonth.year == today.year);

                    // Determine box color:
                    // - selected > primaryContainer
                    // - completed (past & hasMeals) => green tint
                    // - upcoming/current with meals => light blue tint (primary)
                    // - otherwise surface
                    final Color? boxColor = isSelected
                        ? cs.primaryContainer
                        : (hasMeals
                        ? (isPast ? Colors.green.withOpacity(.22) : cs.primary.withOpacity(.12))
                        : cs.surface);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withOpacity(isSelected ? .14 : .08)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 8))]
                            : [BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 6, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _selectDay(day);
                            if (hasMeals) {
                              final mealsForDay = meals.map((m) => Map<String, dynamic>.from(m)).toList();
                              Navigator.push(context, MaterialPageRoute(builder: (_) => DayMealsPage(day: day, meals: mealsForDay)));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No meals available for Day $day")));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // day number row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$day",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? cs.onPrimaryContainer : (isPast ? cs.onSurfaceVariant.withOpacity(.7) : cs.onSurface),
                                        ),
                                      ),
                                    ),
                                    // today pulse (green) - only for current date
                                    if (isToday)
                                      AnimatedBuilder(
                                        animation: _pulseCtrl,
                                        builder: (_, __) {
                                          final scale = 0.8 + 0.4 * _pulseCtrl.value;
                                          final opacity = 0.6 + 0.4 * (1 - (_pulseCtrl.value - 0.5).abs());
                                          return Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green.withOpacity(opacity),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),

                                // intentionally no per-day numeric badge here (we color the box instead)
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: cells.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
              ),
            ),

            // Sticky info / CTA (as a SliverToBoxAdapter so it scrolls into view if needed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(.08)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDay != null
                              ? "Day $_selectedDay • ${selectedMeals.length} meal(s)"
                              : "Select a day to view its meals",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),

                      // Constrain button width so small screens won't overflow.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: ElevatedButton.icon(
                          onPressed: (_selectedDay != null && selectedMeals.isNotEmpty)
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DayMealsPage(day: _selectedDay!, meals: selectedMeals)),
                            );
                          }
                              : null,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Open day"),
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
