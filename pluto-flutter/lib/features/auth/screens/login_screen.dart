import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _sendOtp() async {
    final phone = '+91${_phoneController.text.trim()}';
    setState(() => _loading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
      },
      verificationFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
      },
      codeSent: (verificationId, _) {
        setState(() { _verificationId = verificationId; _otpSent = true; _loading = false; });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp(String otp) async {
    if (_verificationId == null) return;
    setState(() => _loading = true);
    try {
      final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
      await FirebaseAuth.instance.signInWithCredential(cred);
      if (mounted) context.go('/discover');
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [PlutoColors.dark, Color(0xFF2D1B45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PlutoColors.dating,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.public, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text('Pluto', style: TextStyle(fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
                const SizedBox(height: 16),
                Text(
                  _otpSent ? 'Enter the code\nwe sent you' : 'Meet people,\nexplore the world.',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                const Spacer(flex: 3),

                if (!_otpSent) ...[
                  // Phone input
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: const Text('+91', style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        Container(width: 1, height: 24, color: Colors.white24),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontSize: 16),
                            maxLength: 10,
                            decoration: const InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              filled: false,
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PlutoColors.dating,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Get OTP', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600)),
                  ).animate().fadeIn(delay: 500.ms),
                ] else ...[
                  // OTP Pinput
                  Center(
                    child: Pinput(
                      length: 6,
                      autofocus: true,
                      onCompleted: _verifyOtp,
                      defaultPinTheme: PinTheme(
                        width: 52,
                        height: 56,
                        textStyle: const TextStyle(
                          fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Outfit',
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 52,
                        height: 56,
                        textStyle: const TextStyle(
                          fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Outfit',
                        ),
                        decoration: BoxDecoration(
                          color: PlutoColors.dating.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PlutoColors.dating, width: 2),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: Text('Change number', style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Outfit')),
                    ),
                  ),
                ],
                const Spacer(flex: 2),
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontFamily: 'Outfit'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
