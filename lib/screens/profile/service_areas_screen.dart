import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profile_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/regions.dart';

class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({super.key});

  @override
  State<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = {
      ...?context.read<ProfileController>().profile?.serviceAreas.map((e) => e.regionCode),
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileController>().saveServiceAreas(_selected.toList()..sort());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('활동 지역을 저장했습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extras = _selected.where((c) => !seoulRegions.containsKey(c)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('활동 지역')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '선택한 지역으로만 콜이 매칭됩니다. 전체 교체 저장됩니다.',
              style: TextStyle(color: AppColors.body),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in seoulRegions.entries)
                  CheckboxListTile(
                    title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(entry.key),
                    value: _selected.contains(entry.key),
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(entry.key);
                        } else {
                          _selected.remove(entry.key);
                        }
                      });
                    },
                  ),
                for (final code in extras)
                  CheckboxListTile(
                    title: Text(code, style: const TextStyle(fontWeight: FontWeight.w700)),
                    value: true,
                    activeColor: AppColors.primary,
                    onChanged: (_) => setState(() => _selected.remove(code)),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '저장 중…' : '저장'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
