// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_setup.dart';
import 'dashboard.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;

  // for subtle logo bounce
  late final AnimationController _logoCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<User?> signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection("profiles").doc(user.uid).get();
        if (!doc.exists) {
          if (!mounted) return user;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfileSetupPage(userId: user.uid)),
          );
        } else {
          if (!mounted) return user;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      }
      return user;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign in failed: $e")));
      }
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _floatingBlob({required double size, required Alignment alignment, required Color color, required int seed}) {
    // simple decorative blob using AnimatedBuilder on logo controller for subtle movement
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (ctx, child) {
        final t = _logoCtrl.value;
        final dx = (seed % 3 - 1) * 6 * (t - 0.5);
        final dy = (seed % 5 - 2) * 5 * (t - 0.5);
        return Align(
          alignment: alignment,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.25)),
      ),
    );
  }

  Widget _benefitChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // background gradient (static colors from theme) with subtle transform
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.brandBlueLight,
                    AppTheme.brandBlue,
                    AppTheme.brandBlueDark,
                  ],
                ),
              ),
            ).animate().blur(begin: const Offset(6, 6), end: const Offset(0, 0)).scale(begin: const Offset(1.02, 1.02), end: const Offset(1.0, 1.0)),
          ),

          // decorative blobs (non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    _floatingBlob(size: 220, alignment: Alignment.topLeft, color: Colors.white.withOpacity(.04), seed: 3),
                    _floatingBlob(size: 160, alignment: Alignment(0.9, -0.7), color: Colors.white.withOpacity(.03), seed: 7),
                    _floatingBlob(size: 120, alignment: Alignment(-0.9, 0.8), color: Colors.white.withOpacity(.02), seed: 11),
                  ],
                ),
              ),
            ),
          ),

          // MAIN CONTENT: safe + scrollable for small screens
          SafeArea(
            child: Center(
              child: LayoutBuilder(builder: (context, constraints) {
                // keep a comfortable max width for tablets; adapt for narrow phones
                final maxContentWidth = constraints.maxWidth.clamp(0.0, 780.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo + Title row — uses Flexible to avoid overflow
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo container - fixed but small enough for phones
                            ScaleTransition(
                              scale: Tween(begin: 0.96, end: 1.02).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut)),
                              child: Container(
                                width: 84,
                                height: 84,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.brandGradient(),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 8))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset("assets/OG_logo.png", fit: BoxFit.contain),
                                ),
                              ),
                            ).animate().fadeIn(delay: 80.ms),

                            const SizedBox(width: 12),

                            // Title + tagline — Flexible so it wraps on small widths
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Satwik Diet",
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 160.ms),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Personalized meal plans • Ayurvedic wisdom",
                                    style: GoogleFonts.inter(color: Colors.white.withOpacity(.92), fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ).animate().fadeIn(delay: 220.ms),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Responsive hero card: switches between Row and Column for narrow widths
                        LayoutBuilder(builder: (ctx, box) {
                          final narrow = box.maxWidth < 420;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(.06),
                              border: Border.all(color: Colors.white.withOpacity(.06)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 20, offset: const Offset(0, 12))],
                            ),
                            child: narrow
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Eat well, live well", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)).animate().fadeIn(delay: 260.ms),
                                const SizedBox(height: 8),
                                Text(
                                  "Generate a 30-day plan tailored to your body, goals and lifestyle. Explore foods with Ayurvedic tags and track progress.",
                                  style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
                                ).animate().fadeIn(delay: 320.ms),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  _benefitChip(Icons.auto_graph, "Goal-driven plans"),
                                  _benefitChip(Icons.search, "Explore foods"),
                                  _benefitChip(Icons.notifications, "Reminders"),
                                ]).animate().fadeIn(delay: 380.ms),
                                const SizedBox(height: 12),
                                // Illustration below text on narrow screens
                                Center(
                                  child: SizedBox(
                                    height: 120,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset("assets/illustration_onboarding.png", fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              children: [
                                // Text block
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Eat well, live well", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)).animate().fadeIn(delay: 260.ms),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Generate a 30-day plan tailored to your body, goals and lifestyle. Explore foods with Ayurvedic tags and track progress.",
                                        style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
                                      ).animate().fadeIn(delay: 320.ms),
                                      const SizedBox(height: 12),
                                      Wrap(spacing: 8, runSpacing: 8, children: [
                                        _benefitChip(Icons.auto_graph, "Goal-driven plans"),
                                        _benefitChip(Icons.search, "Explore foods"),
                                        _benefitChip(Icons.notifications, "Reminders"),
                                      ]).animate().fadeIn(delay: 380.ms),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Illustration on the right for larger screens
                                Expanded(
                                  flex: 4,
                                  child: SizedBox(
                                    height: 120,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset("assets/illustration_onboarding.png", fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Sign-in card: constrained so it never exceeds screen
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withOpacity(.06),
                            border: Border.all(color: Colors.white.withOpacity(.06)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Start your health journey", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text("Sign in to generate your personalized meal plan and save progress across devices.", style: GoogleFonts.inter(color: Colors.white70)),
                              const SizedBox(height: 12),

                              // Google sign-in button (constrained)
                              ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 48, maxWidth: 700),
                                child: GestureDetector(
                                  onTap: _loading ? null : signInWithGoogle,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: _loading ? 0.8 : 1.0,
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 12, offset: const Offset(0, 8)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 36,
                                            height: 36,
                                            padding: const EdgeInsets.all(6),
                                            child: Image.asset("assets/google-logo.png", fit: BoxFit.contain),
                                          ),
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 260),
                                              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                              child: Text(
                                                _loading ? "Signing in..." : "Continue with Google",
                                                key: ValueKey(_loading),
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Center(child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black54)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 360.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1.0, 1.0)),
                              ),

                              const SizedBox(height: 10),

                              // small legal / privacy text (keeps one line)
                              Text(
                                "We only use your profile to personalize your experience.",
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, height: 1.3),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
