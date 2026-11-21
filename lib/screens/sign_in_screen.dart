import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid university email');
      return;
    }
    final user = AuthService.signIn(email);
    // Different emails open different dashboards.
    Navigator.pushReplacementNamed(
      context,
      user.role == UserRole.management ? AppRoutes.management : AppRoutes.home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeroHeader(
            imageAsset: 'assets/images/campus.jpg',
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Logo(light: true),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                const Text('Welcome back',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Sign in to MYREPAIR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Report. Track. Fix. Keep our campus running.',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('University email'),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'name@university.edu',
                    errorText: _error,
                    prefixIcon:
                        const Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const FieldLabel('Password'),
                TextField(
                  controller: _password,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign in'),
                ),
                const SizedBox(height: 22),
                const Text('Demo accounts (tap to fill)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TarumtColors.muted)),
                const SizedBox(height: 8),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    _DemoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Student / reporter',
                      email: 'student@student.tarc.edu.my',
                      onTap: () => setState(
                          () => _email.text = 'student@student.tarc.edu.my'),
                    ),
                    const Divider(height: 1),
                    _DemoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Management',
                      email: 'management@tarc.edu.my',
                      onTap: () => setState(
                          () => _email.text = 'management@tarc.edu.my'),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String email;
  final VoidCallback onTap;
  const _DemoRow(
      {required this.icon,
      required this.label,
      required this.email,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            IconBadge(icon, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 11, color: TarumtColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.north_west_rounded,
                size: 14, color: TarumtColors.muted),
          ]),
        ),
      );
}
