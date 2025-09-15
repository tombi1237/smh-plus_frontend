class OTPService {
  Future<bool> verifyOTP(String otpCode) async {
    // Implémentez la logique de vérification OTP ici
    await Future.delayed(const Duration(seconds: 2));
    return otpCode == '123456'; // Exemple de code de test
  }

  Future<void> resendOTP(String email) async {
    // Implémentez la logique de renvoi d'OTP ici
    await Future.delayed(const Duration(seconds: 1));
  }
}
