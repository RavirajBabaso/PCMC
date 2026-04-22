class Constants {
  static String get baseUrl => 'https://pcmc.onrender.com';

  static final Uri _baseUri = Uri.parse(baseUrl);

  static String? resolveMediaUrl(String? rawPath, {bool assumeUploadPath = true}) {
    final value = rawPath?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('//')) {
      return '${_baseUri.scheme}:$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      if (_isLoopbackHost(parsed.host)) {
        return _baseUri
            .replace(path: parsed.path, query: parsed.query.isEmpty ? null : parsed.query)
            .toString();
      }
      return parsed.toString();
    }

    var normalized = value.replaceAll('\\', '/');

    if (normalized.contains('uploads/')) {
      final uploadsIndex = normalized.indexOf('uploads/');
      normalized = normalized.substring(uploadsIndex);
      if (!normalized.startsWith('/')) {
        normalized = '/$normalized';
      }
      return _baseUri.resolve(normalized).toString();
    }

    if (normalized.startsWith('/')) {
      return _baseUri.resolve(normalized).toString();
    }

    if (assumeUploadPath) {
      return _baseUri.resolve('/uploads/$normalized').toString();
    }

    return _baseUri.resolve('/$normalized').toString();
  }

  static bool _isLoopbackHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' || h == '127.0.0.1' || h == '0.0.0.0' || h == '10.0.2.2';
  }
}
