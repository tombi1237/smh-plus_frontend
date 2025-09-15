class OTPData {
  final String code;
  final List<String> digits;
  final bool isComplete;

  OTPData({required this.code, required this.digits, required this.isComplete});

  OTPData.empty()
    : code = '',
      digits = ['', '', '', '', '', ''],
      isComplete = false;

  OTPData addDigit(String digit) {
    if (code.length >= 6) return this;

    final newCode = code + digit;
    final newDigits = List<String>.from(digits);
    newDigits[newCode.length - 1] = digit;

    return OTPData(
      code: newCode,
      digits: newDigits,
      isComplete: newCode.length == 6,
    );
  }

  OTPData removeDigit() {
    if (code.isEmpty) return this;

    final newCode = code.substring(0, code.length - 1);
    final newDigits = List<String>.from(digits);
    newDigits[code.length - 1] = '';

    return OTPData(code: newCode, digits: newDigits, isComplete: false);
  }
}
