import 'dart:math';

/// High-performance string distance (Damerau-Levenshtein) and phonetic matching.
/// Used to dynamically correct technician speech recognition slips without
/// requiring hardcoded regex substitutions for every word variation.
class FuzzyMatcher {
  /// Computes the Damerau-Levenshtein distance between two strings,
  /// supporting insertions, deletions, substitutions, and adjacent transpositions.
  static int levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final d = List.generate(
      s1.length + 1,
      (_) => List<int>.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = (s1.codeUnitAt(i - 1) == s2.codeUnitAt(j - 1)) ? 0 : 1;
        d[i][j] = min(
          d[i - 1][j] + 1, // deletion
          min(
            d[i][j - 1] + 1, // insertion
            d[i - 1][j - 1] + cost, // substitution
          ),
        );

        // Damerau adjacent transposition
        if (i > 1 &&
            j > 1 &&
            s1.codeUnitAt(i - 1) == s2.codeUnitAt(j - 2) &&
            s1.codeUnitAt(i - 2) == s2.codeUnitAt(j - 1)) {
          d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1);
        }
      }
    }

    return d[s1.length][s2.length];
  }

  /// Calculates simplified phonetic signature (Soundex-like) for acoustic matching.
  static String phoneticCode(String word) {
    final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (clean.isEmpty) return '';

    final buffer = StringBuffer(clean[0]);
    for (var i = 1; i < clean.length; i++) {
      final char = clean[i];
      final code = _charToPhoneticDigit(char);
      if (code != '0' &&
          (buffer.isEmpty || buffer.toString()[buffer.length - 1] != code)) {
        buffer.write(code);
      }
    }

    final result = buffer.toString().padRight(4, '0');
    return result.substring(0, min(4, result.length));
  }

  static String _charToPhoneticDigit(String char) {
    switch (char) {
      case 'b':
      case 'f':
      case 'p':
      case 'v':
        return '1';
      case 'c':
      case 'g':
      case 'j':
      case 'k':
      case 'q':
      case 's':
      case 'x':
      case 'z':
        return '2';
      case 'd':
      case 't':
        return '3';
      case 'l':
        return '4';
      case 'm':
      case 'n':
        return '5';
      case 'r':
        return '6';
      default:
        return '0';
    }
  }

  /// Returns true if [spoken] matches [candidate] within [maxEditDistance]
  /// or shares an acoustic phonetic signature.
  static bool isMatch(
    String spoken,
    String candidate, {
    int maxEditDistance = 2,
  }) {
    final s1 = spoken.toLowerCase().trim();
    final s2 = candidate.toLowerCase().trim();

    if (s1 == s2) return true;
    if ((s1.length - s2.length).abs() > maxEditDistance) return false;

    // Direct edit distance
    final dist = levenshtein(s1, s2);
    if (dist <= maxEditDistance) return true;

    // Phonetic signature fallback (for words length >= 4)
    if (s1.length >= 4 && s2.length >= 4) {
      if (phoneticCode(s1) == phoneticCode(s2)) {
        return dist <= maxEditDistance + 1;
      }
    }

    return false;
  }

  /// Finds the best matching candidate from [candidates], or returns null if none is close.
  static String? findBestMatch(
    String word,
    Iterable<String> candidates, {
    int maxDistance = 2,
  }) {
    final target = word.toLowerCase().trim();
    String? bestCandidate;
    var bestDistance = maxDistance + 1;

    for (final candidate in candidates) {
      final candLower = candidate.toLowerCase().trim();
      if (target == candLower) return candidate;

      final dist = levenshtein(target, candLower);
      if (dist < bestDistance) {
        bestDistance = dist;
        bestCandidate = candidate;
      }
    }

    return (bestDistance <= maxDistance) ? bestCandidate : null;
  }
}
