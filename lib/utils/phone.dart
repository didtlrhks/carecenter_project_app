import 'package:flutter/services.dart';

/// 표시용 하이픈. 전송 시에는 [digitsOnly] 사용.
String formatPhoneDisplay(String raw) {
  final d = digitsOnly(raw);
  if (d.length <= 3) return d;
  if (d.length <= 7) return '${d.substring(0, 3)}-${d.substring(3)}';
  if (d.length <= 11) {
    return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  }
  return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7, 11)}';
}

String digitsOnly(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

class PhoneHyphenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneDisplay(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
