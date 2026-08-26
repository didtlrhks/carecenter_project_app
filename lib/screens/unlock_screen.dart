import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/phone.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    await auth.unlockWithBiometrics();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _usePassword() async {
    await context.read<AuthController>().unlockWithPasswordFallback();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final name = auth.user?.name;
    final phone = auth.user?.phone;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.fingerprint, size: 72, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                name == null ? '다시 열어주세요' : '$name 님',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (phone != null) ...[
                const SizedBox(height: 8),
                Text(
                  formatPhoneDisplay(phone),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFADB7BE), fontSize: 16),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                '지문 또는 얼굴로 앱을 엽니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFADB7BE), fontSize: 16),
              ),
              if (auth.lastError != null) ...[
                const SizedBox(height: 16),
                Text(
                  auth.lastError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFB4A8), fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _busy ? null : _unlock,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: Text(
                  _busy ? '확인 중…' : '지문·얼굴로 열기',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _usePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF5A7184)),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('비밀번호로 로그인', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
