class ValidationUtils {
  // Email Validation Model
  static const String emailRegexStr =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  static final RegExp _emailRegExp = RegExp(emailRegexStr);

  static const List<String> blockedDomains = [
    'tempmail.com',
    'mailinator.com',
    'yopmail.com',
    'guerrillamail.com',
    'sharklasers.com',
    'dispostable.com',
    'getairmail.com',
  ];

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NEURAL LINK ADDR REQUIRED';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'INVALID NEURAL LINK FORMAT';
    }
    final domain = trimmed.split('@').last.toLowerCase();
    if (blockedDomains.contains(domain)) {
      return 'SECURITY EXCLUSION: TEMP DOMAIN BLOCKED';
    }
    return null;
  }

  // Username Validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NETRUNNER TAG REQUIRED';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'TAG TOO SHORT (MIN 3 CHARS)';
    }
    if (trimmed.contains(' ')) {
      return 'TAG SPACES PROHIBITED';
    }
    // Only lowercase alphanumeric & underscores allowed
    final usernameRegExp = RegExp(r'^[a-z0-9_]+$');
    if (!usernameRegExp.hasMatch(trimmed)) {
      return 'LOWERCASE, DIGITS & UNDERSCORE ONLY';
    }
    return null;
  }

  // Password Realtime Strength Checker
  static bool hasMinLength(String val) => val.length >= 8;
  static bool hasUppercase(String val) => val.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String val) => val.contains(RegExp(r'[a-z]'));
  static bool hasNumber(String val) => val.contains(RegExp(r'[0-9]'));
  static bool hasSpecialChar(String val) =>
      val.contains(RegExp(r'[!@#\$&*~_.-]'));

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'ACCESS CORE KEY REQUIRED';
    }
    if (!hasMinLength(value)) {
      return 'KEY ACCESS DENIED: MIN 8 CHARACTERS';
    }
    if (!hasUppercase(value)) {
      return 'KEY ACCESS DENIED: UPPERCASE KEY MISSING';
    }
    if (!hasLowercase(value)) {
      return 'KEY ACCESS DENIED: LOWERCASE KEY MISSING';
    }
    if (!hasNumber(value)) {
      return 'KEY ACCESS DENIED: DIGIT KEY MISSING';
    }
    if (!hasSpecialChar(value)) {
      return 'KEY ACCESS DENIED: SPECIAL CHAR KEY MISSING';
    }
    return null;
  }
}
