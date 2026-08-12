import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/api_error.dart';
import '../services/token_store.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';

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
    if (kDebugMode) {
      _id.text = '01012345678';
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
    final id = _id.text.replaceAll(RegExp(r'[^0-9+]'), '');
    final password = _password.text;
    if (id.isEmpty || password.isEmpty) {
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
      if (_server.text.trim().isNotEmpty) {
        await store.setApiBaseUrl(_server.text.trim());
        auth.api.applyBaseUrl(store.apiBaseUrl);
      }
      await auth.login(id, password);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '로그인에 실패했습니다. 서버 주소를 확인해 주세요.');
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
                  const SizedBox(height: 24),
                  const Text(
                    '요양보호사',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '근무 콜에 응답하고\n확정된 일정을 확인하세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '[가능]은 지원입니다. 센터가 최종 수락해야 확정됩니다.',
                    style: TextStyle(color: Color(0xFFADB7BE), height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('전화번호', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.heading)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _id,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: '01012345678'),
                        ),
                        const SizedBox(height: 16),
                        const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.heading)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: '비밀번호',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Text(_busy ? '로그인 중…' : '로그인'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _showServer = !_showServer),
                    child: Text(
                      _showServer ? '서버 설정 닫기' : '서버 설정',
                      style: const TextStyle(color: Color(0xFFADB7BE)),
                    ),
                  ),
                  if (_showServer)
                    TextField(
                      controller: _server,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.0.10:3000/api/v1',
                        hintStyle: TextStyle(color: Color(0xFF7B8FA3)),
                        filled: true,
                        fillColor: Color(0xFF35495D),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
