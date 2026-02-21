const Set<String> _sensitiveQueryKeys = {
  'code',
  'token',
  'access_token',
  'refresh_token',
  'session',
  'cookie',
  'authorization',
};

bool _isSensitiveKey(String key) {
  return _sensitiveQueryKeys.contains(key.toLowerCase());
}

String redactSensitive(String input) {
  var output = input;

  output = output.replaceAllMapped(
    RegExp(
      r'([?&](?:code|token|access_token|refresh_token|session|cookie|authorization)=)([^&#\s]+)',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}<redacted>',
  );

  output = output.replaceAllMapped(
    RegExp(r'\b(Bearer)\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    (match) => '${match.group(1)} <redacted>',
  );

  output = output.replaceAllMapped(
    RegExp(
      r'\b(authorization)\s*[:=]\s*.*?(?=(?:\s+\b(?:cookie|set-cookie)\b)|,|\n|$)',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}: <redacted>',
  );

  output = output.replaceAllMapped(
    RegExp(r'\b(cookie|set-cookie)\s*[:=]\s*[^,\n]+', caseSensitive: false),
    (match) => '${match.group(1)}: <redacted>',
  );

  return output;
}

String sanitizeUrlForLog(String rawUrl, {bool keepQuery = false}) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return redactSensitive(rawUrl);
  }

  if (!keepQuery || uri.queryParameters.isEmpty) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return '${uri.scheme}://${uri.host}$path';
  }

  final redactedQuery = <String, String>{};
  for (final entry in uri.queryParameters.entries) {
    redactedQuery[entry.key] =
        _isSensitiveKey(entry.key) ? '<redacted>' : entry.value;
  }

  return uri.replace(queryParameters: redactedQuery).toString();
}

String sanitizeUriForLog(Uri uri, {bool keepQuery = false}) {
  return sanitizeUrlForLog(uri.toString(), keepQuery: keepQuery);
}

String sanitizeObjectForLog(Object? value) {
  return redactSensitive(value?.toString() ?? 'null');
}
