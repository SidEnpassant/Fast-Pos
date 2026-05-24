/// Builds trigram/prefix tokens for offline product search.
abstract final class InvertedIndexBuilder {
  static List<String> tokenize(String name) {
    final normalized = name.toLowerCase().trim();
    if (normalized.isEmpty) return const [];

    final tokens = <String>{normalized};
    final words = normalized.split(RegExp(r'\s+'));
    for (final w in words) {
      if (w.length < 2) continue;
      tokens.add(w);
      for (var i = 2; i <= w.length && i <= 4; i++) {
        tokens.add(w.substring(0, i));
      }
      if (w.length >= 3) {
        for (var i = 0; i <= w.length - 3; i++) {
          tokens.add(w.substring(i, i + 3));
        }
      }
    }
    return tokens.toList();
  }
}
