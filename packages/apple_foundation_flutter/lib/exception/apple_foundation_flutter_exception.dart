class AppleFoundationException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppleFoundationException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AppleFoundationException: $message${code != null ? ' (Code: $code)' : ''}${details != null ? ' Details: $details' : ''}';
}

