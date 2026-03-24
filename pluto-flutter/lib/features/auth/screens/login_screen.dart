import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  bool _showPhoneInput = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      // Let app_router handle the redirect (to discover or onboarding)
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
      }
    }
  }

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
      // app_router handles redirect
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Try again.')));
    }
  }

  Widget _buildSocialButton({required IconData icon, required String text, required VoidCallback onTap, required Color bgColor, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onTap,
        icon: Icon(icon, color: textColor),
        label: Text(text, style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PlutoColors.dark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 40),
              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 16),
              const Text('Pluto', style: TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 8),
              Text(
                'Explore the universe within.',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.grey.shade600),
              ),
              const Spacer(),

              if (!_showPhoneInput) ...[
                // Main Options
                _buildSocialButton(
                  icon: Icons.email_outlined,
                  text: 'Continue with Email',
                  bgColor: PlutoColors.dark,
                  textColor: Colors.white,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                
                _buildSocialButton(
                  icon: Icons.phone_android,
                  text: 'Continue with Mobile',
                  bgColor: Colors.grey.shade100,
                  textColor: Colors.black,
                  onTap: () => setState(() => _showPhoneInput = true),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  text: 'Continue with Google',
                  bgColor: Colors.grey.shade100,
                  textColor: Colors.black,
                  onTap: _signInWithGoogle,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {},
                  child: const Text('Create an account', style: TextStyle(fontFamily: 'Outfit', color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                ).animate().fadeIn(delay: 400.ms),
              ] else if (!_otpSent) ...[
                // Phone input
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _showPhoneInput = false),
                    ),
                    const Expanded(child: Text('Enter your phone number', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: const Text('+91', style: TextStyle(color: Colors.black, fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Container(width: 1, height: 24, color: Colors.black12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.black, fontFamily: 'Outfit', fontSize: 16),
                          maxLength: 10,
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PlutoColors.dark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Get OTP', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                // OTP Pinput
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _otpSent = false),
                    ),
                    const Expanded(child: Text('Enter the OTP', style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Pinput(
                    length: 6,
                    autofocus: true,
                    onCompleted: _verifyOtp,
                    defaultPinTheme: PinTheme(
                      width: 52,
                      height: 56,
                      textStyle: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 52,
                      height: 56,
                      textStyle: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PlutoColors.dark, width: 2),
                      ),
                    ),
                  ),
                ).animate().fadeIn(),
              ],

              const Spacer(),
              if (_loading) const Center(child: CircularProgressIndicator()),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'By continuing, you agree to our Terms of Service and\nPrivacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'Outfit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
