import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'services/api_service.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');
  final savedTheme = prefs.getString('theme_mode');

  ThemeMode initialThemeMode;
  switch (savedTheme) {
    case 'light':
      initialThemeMode = ThemeMode.light;
      break;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    default:
      initialThemeMode = ThemeMode.system;
  }

  runApp(
    ClinicManagementApp(
      savedToken: savedToken,
      initialThemeMode: initialThemeMode,
    ),
  );
}

// ================================================================
// MAIN APP
// ================================================================

class ClinicManagementApp extends StatefulWidget {
  final String? savedToken;
  final ThemeMode initialThemeMode;

  const ClinicManagementApp({
    super.key,
    this.savedToken,
    required this.initialThemeMode,
  });

  @override
  State<ClinicManagementApp> createState() => _ClinicManagementAppState();
}

class _ClinicManagementAppState extends State<ClinicManagementApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarePoint Medical',
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: widget.savedToken != null && widget.savedToken!.isNotEmpty
          ? Dashboard(
              token: widget.savedToken!,
              onThemeChanged: _changeTheme,
              currentThemeMode: _themeMode,
            )
          : const LoginScreen(),
    );
  }
}

// ================================================================
// LOGIN SCREEN WITH MOTION BG, MOVING ECG & INTERACTIVE MASCOT
// ================================================================

class LoginScreen extends StatefulWidget {
  final Future<void> Function(ThemeMode mode)? onThemeChanged;
  final ThemeMode currentThemeMode;

  const LoginScreen({
    super.key,
    this.onThemeChanged,
    this.currentThemeMode = ThemeMode.system,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController(text: 'aoun@clinic.com');
  final _passwordController = TextEditingController(text: 'aoun123!');

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late AnimationController _bgAnimationController;
  late AnimationController _ecgAnimationController;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _ecgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _ecgAnimationController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      final String token =
          (response['token'] ??
                  response['access_token'] ??
                  response['auth_token'] ??
                  '')
              .toString();

      if (token.isEmpty) {
        throw Exception('Token not found in login response');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Dashboard(
            token: token,
            onThemeChanged: _getThemeChangeCallback(),
            currentThemeMode: _getCurrentThemeMode(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> Function(ThemeMode)? _getThemeChangeCallback() {
    if (widget.onThemeChanged != null) {
      return widget.onThemeChanged;
    }

    final appState = context
        .findAncestorStateOfType<_ClinicManagementAppState>();
    return appState?._changeTheme;
  }

  ThemeMode _getCurrentThemeMode() {
    if (widget.onThemeChanged != null) {
      return widget.currentThemeMode;
    }

    final appState = context
        .findAncestorStateOfType<_ClinicManagementAppState>();
    return appState?._themeMode ?? ThemeMode.system;
  }

  @override
  Widget build(BuildContext context) {
    final isCoveringEyes = _isPasswordVisible;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1B),
      body: Stack(
        children: [
          // ------------------------------------------------------
          // MOTION BACKGROUND GRADIENT ORBS
          // ------------------------------------------------------
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              final t = _bgAnimationController.value;
              final sinT = math.sin(t * 2 * math.pi);
              final cosT = math.cos(t * 2 * math.pi);

              return Stack(
                children: [
                  Positioned(
                    top: -100 + (sinT * 40),
                    left: -100 + (cosT * 40),
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 + (cosT * 50),
                    right: -100 + (sinT * 50),
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4 + (cosT * 30),
                    left: MediaQuery.of(context).size.width * 0.2 + (sinT * 30),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ------------------------------------------------------
          // GLASS BACKDROP LAYER
          // ------------------------------------------------------
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: const SizedBox.expand(),
            ),
          ),

          // ------------------------------------------------------
          // LOGIN CONTENT
          // ------------------------------------------------------
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedMascot(isCoveringEyes),
                  const SizedBox(height: 18),
                  _buildGlassLoginCard(context),
                  const SizedBox(height: 28),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMATED INTERACTIVE MASCOT
  // ============================================================

  Widget _buildAnimatedMascot(bool isCoveringEyes) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCoveringEyes
              ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCoveringEyes
                ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Text(
          isCoveringEyes ? '🙈' : (_passwordFocus.hasFocus ? '🤫' : '🐵'),
          key: ValueKey<String>(
            isCoveringEyes
                ? 'covering'
                : (_passwordFocus.hasFocus ? 'typing_pass' : 'open'),
          ),
          style: const TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildGlassLoginCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF131F37).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 32, 30, 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildMedicalHeader(),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    _buildErrorMessage(),
                    const SizedBox(height: 18),
                  ],
                  _buildInputField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    label: 'Username / Email',
                    hint: 'Enter your username or ID',
                    prefixIcon: Icons.person_outline_rounded,
                    isFocusedGlow: _usernameFocus.hasFocus,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Icons.lock_outline_rounded,
                    isFocusedGlow: _passwordFocus.hasFocus,
                    suffixWidget: IconButton(
                      tooltip: _isPasswordVisible
                          ? 'Hide Password'
                          : 'Show Password',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          key: ValueKey<bool>(_isPasswordVisible),
                          size: 20,
                          color: _isPasswordVisible
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildLoginLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFCA5A5),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICAL HEADER WITH ANIMATED MOVING ECG
  // ============================================================

  Widget _buildMedicalHeader() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ecgAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(220, 36),
                    painter: MovingEcgPulsePainter(
                      progress: _ecgAnimationController.value,
                    ),
                  );
                },
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.55),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'CarePoint Medical',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clinical Staff Authentication',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixWidget,
    bool obscureText = false,
    bool isFocusedGlow = false,
    String? Function(String?)? validator,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFocusedGlow
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0B132B).withValues(alpha: 0.65),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: isFocusedGlow
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withValues(alpha: 0.6),
                size: 19,
              ),
              suffixIcon: suffixWidget,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF38BDF8),
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFF131F37),
            child: Text(
              label,
              style: TextStyle(
                color: isFocusedGlow
                    ? const Color(0xFF7DD3FC)
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // LOGIN LINKS
  // ============================================================

  Widget _buildLoginLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            'Register Staff',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER WITH AOUN-DEV CREDITS
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            Text(
              'Knox Standards',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code_rounded, size: 14, color: Color(0xFF60A5FA)),
            const SizedBox(width: 6),
            Text(
              'Developed by Aoun Dev',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// CONTINUOUS MOVING ECG / LIFE-LINE PAINTER
// ================================================================

class MovingEcgPulsePainter extends CustomPainter {
  final double progress;

  MovingEcgPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.20)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pulsePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h = size.height / 2;
    final w = size.width;

    // Generate single ECG waveform cycle
    double getEcgOffset(double xNormalized) {
      final x = (xNormalized + (1.0 - progress)) % 1.0;

      if (x > 0.15 && x <= 0.22) {
        return -4.0 * math.sin((x - 0.15) / 0.07 * math.pi); // P wave
      } else if (x > 0.25 && x <= 0.28) {
        return 4.0 * math.sin((x - 0.25) / 0.03 * math.pi); // Q wave
      } else if (x > 0.28 && x <= 0.35) {
        return -18.0 * math.sin((x - 0.28) / 0.07 * math.pi); // R peak
      } else if (x > 0.35 && x <= 0.40) {
        return 8.0 * math.sin((x - 0.35) / 0.05 * math.pi); // S wave
      } else if (x > 0.46 && x <= 0.58) {
        return -7.0 * math.sin((x - 0.46) / 0.12 * math.pi); // T wave
      }
      return 0.0;
    }

    final path = Path();
    const steps = 140;

    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * w;
      final y = h + getEcgOffset(i / steps);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, basePaint);
    canvas.drawPath(path, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant MovingEcgPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
