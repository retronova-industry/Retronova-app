class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Session expirée'])
    : super(statusCode: 401);
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Erreur réseau']) : super();
}
