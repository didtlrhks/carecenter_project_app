import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/dev_settings.dart';
import '../config/env.dart';
import '../models/api_error.dart';
import '../services/token_store.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/phone.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _server = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  bool _showServer = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<TokenStore>();
    _server.text = store.apiBaseUrl;
    final last = store.lastPhone;
    if (last != null && last.isNotEmpty) {
      _id.text = formatPhoneDisplay(last);
    } else if (kDebugMode) {
      _id.text = formatPhoneDisplay('01012345678');
    }
    // 로그아웃 후에도 번호만 채워지고 비번이 비어 “로그인이 안 됨”처럼 보이던 문제 방지
    if (kDebugMode) {
      _password.text = 'Caregiver123!';
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = digitsOnly(_id.text);
    final password = _password.text;
    if (id.length < 10 || password.isEmpty) {
      setState(() => _error = '전화번호와 비밀번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final store = context.read<TokenStore>();
    try {
      final server = _server.text.trim();
      if (server.isNotEmpty) {
        await store.setApiBaseUrl(server);
        auth.api.applyBaseUrl(store.apiBaseUrl);
      }
      await auth.login(id, password);
      // 생체 안내는 AuthGate에서 처리 (로그인 화면이 바로 dispose 되므로 여기서 띄우지 않음)
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        if (e.code == 'NETWORK') _showServer = true;
      });
    } catch (_) {
      setState(() {
        _error = '로그인에 실패했습니다.\n센터에 등록된 번호인지 확인해 주세요.';
        _showServer = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '요양보호사',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '전화번호로\n로그인하세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '센터에 등록된 번호만 사용할 수 있습니다.\n비밀번호를 모르면 센터에 문의해 주세요.',
                    style: TextStyle(color: Color(0xFFADB7BE), height: 1.45, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '전화번호',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _id,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            PhoneHyphenFormatter(),
                          ],
                          decoration: const InputDecoration(
                            hintText: '010-1234-5678',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '비밀번호',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.heading, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: '센터에서 알려준 비밀번호',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                          child: Text(
                            _busy ? '로그인 중…' : '로그인',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showServer = !_showServer),
                    child: Text(
                      _showServer ? '서버 설정 닫기' : '서버 설정',
                      style: const TextStyle(color: Color(0xFFADB7BE)),
                    ),
                  ),
                  if (_showServer) ...[
                    Text(
                      '기본 API: $kApiBaseUrl',
                      style: const TextStyle(color: Color(0xFFADB7BE), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _server,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: Env.defaultBaseUrl(),
                        hintStyle: const TextStyle(color: Color(0xFF7B8FA3)),
                        filled: true,
                        fillColor: const Color(0xFF35495D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
