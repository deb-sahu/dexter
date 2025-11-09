import 'dart:math';

/// Generates a cryptographically secure random password
/// 
/// [length] - Password length (default: 16, min: 8, max: 64)
/// [excludeAmbiguous] - Exclude similar-looking characters (0,O,l,1,I) (default: true)
/// 
/// Returns a strong password with:
/// - Uppercase letters (A-Z)
/// - Lowercase letters (a-z)
/// - Digits (0-9)
/// - Special characters (!@#$%^&*()_+-=[]{}|;:,.<>?)
String generateStrongPassword({
  int length = 16,
  bool excludeAmbiguous = true,
}) {
  // Validate length
  if (length < 8) length = 8;
  if (length > 64) length = 64;

  // Character sets
  String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String lowercase = 'abcdefghijklmnopqrstuvwxyz';
  String digits = '0123456789';
  const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // Exclude ambiguous characters if requested
  if (excludeAmbiguous) {
    uppercase = uppercase.replaceAll(RegExp(r'[OI]'), ''); // Remove O, I
    lowercase = lowercase.replaceAll(RegExp(r'[lo]'), ''); // Remove l, o
    digits = digits.replaceAll(RegExp(r'[01]'), ''); // Remove 0, 1
  }

  // Use cryptographically secure random generator
  final secureRandom = Random.secure();

  // Build password ensuring at least one from each category
  List<String> passwordChars = [];

  // Guarantee minimum one from each category
  passwordChars.add(uppercase[secureRandom.nextInt(uppercase.length)]);
  passwordChars.add(lowercase[secureRandom.nextInt(lowercase.length)]);
  passwordChars.add(digits[secureRandom.nextInt(digits.length)]);
  passwordChars.add(specialChars[secureRandom.nextInt(specialChars.length)]);

  // Combine all character sets for remaining characters
  String allChars = uppercase + lowercase + digits + specialChars;

  // Fill remaining length with random characters
  for (int i = passwordChars.length; i < length; i++) {
    passwordChars.add(allChars[secureRandom.nextInt(allChars.length)]);
  }

  // Cryptographically secure shuffle
  for (int i = passwordChars.length - 1; i > 0; i--) {
    int j = secureRandom.nextInt(i + 1);
    String temp = passwordChars[i];
    passwordChars[i] = passwordChars[j];
    passwordChars[j] = temp;
  }

  return passwordChars.join();
}
