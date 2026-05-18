// Ei class ta users er input (email, password, username) validate korar jonno banano hoyeche.
// Beginner coder ra jeno shohojei bujhte pare password strength ar regex kivabe kaj kore.
class ValidationUtils {
  // Strong Email Regex checking for format and domain validity
  // Ei regex pattern ta check kore email valid formats follow korche kina (e.g. user@domain.com)
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Common disposable/invalid domain list
  // Kono user jeno fake ba disposable temporary email diye registration korte na pare tar list
  static const List<String> _invalidDomains = [
    'test.com',
    'example.com',
    'dummy.com',
    'mailinator.com',
    'tempmail.com',
  ];

  /// Validates an email address.
  /// Returns null if valid, or an error string if invalid.
  // Ei function ta check kore email empty kina, regex er sathe match kore kina, ar domain list clean kina.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Invalid email format';
    }
    final parts = trimmed.split('@');
    if (parts.length == 2) {
      final domain = parts[1].toLowerCase();
      if (_invalidDomains.contains(domain)) {
        return 'Please use a valid non-test email domain';
      }
    }
    return null;
  }

  /// Evaluates password strength.
  /// Checks uppercase, lowercase, numbers, special characters, and minimum length.
  // Password er specific requirements (uppercase, lowercase, number, symbol) check kore true/false map pathay.
  static Map<String, bool> evaluatePasswordStrength(String password) {
    return {
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasDigits': password.contains(RegExp(r'[0-9]')),
      'hasSpecial': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      'isMinLength': password.length >= 8,
    };
  }

  /// Calculates a numerical strength score (0 to 1).
  // evaluatePasswordStrength map analyze kore numerical value (0.0 to 1.0) count kore custom gauge widget er jonno.
  static double getPasswordStrengthScore(String password) {
    if (password.isEmpty) return 0.0;
    final checks = evaluatePasswordStrength(password);
    int score = 0;
    if (checks['hasUppercase']!) score++;
    if (checks['hasLowercase']!) score++;
    if (checks['hasDigits']!) score++;
    if (checks['hasSpecial']!) score++;
    if (checks['isMinLength']!) score++;
    return score / 5.0;
  }

  /// Gets password strength text.
  // System password encryption logic label display korar dynamic status text generator.
  static String getPasswordStrengthText(String password) {
    final score = getPasswordStrengthScore(password);
    if (score == 0.0) return 'NO INPUT';
    if (score <= 0.4) return 'WEAK PROTOCOL';
    if (score <= 0.8) return 'MODERATE DECRYPTION';
    return 'SECURE SYSTEM ENCRYPTED';
  }

  /// Validates password value.
  // Validation checks structure sequence standard error alert generation handler.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final checks = evaluatePasswordStrength(value);
    if (!checks['isMinLength']!) {
      return 'Must be at least 8 characters';
    }
    if (!checks['hasUppercase']! || !checks['hasLowercase']!) {
      return 'Must contain uppercase and lowercase';
    }
    if (!checks['hasDigits']!) {
      return 'Must contain at least one number';
    }
    if (!checks['hasSpecial']!) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  /// Validates username format.
  /// Requirements: no spaces, lowercase-only, minimum 3 chars.
  // Cyberpunk console commands compatibility er jonno username validation rules: strict lowercase, spaces allowed na.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Must be at least 3 characters';
    }
    if (trimmed.contains(' ')) {
      return 'Spaces are not allowed';
    }
    if (trimmed != trimmed.toLowerCase()) {
      return 'Must be in lowercase only';
    }
    if (!RegExp(r'^[a-z0-9_.-]+$').hasMatch(trimmed)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }
}
