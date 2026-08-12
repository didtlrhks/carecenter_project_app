class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  bool get isNotFound => status == 404 || code == 'RESOURCE_NOT_FOUND';
  bool get isNotInvited => code == 'NOT_INVITED' || isNotFound;
  bool get isUnauthenticated => status == 401 || code == 'UNAUTHENTICATED';

  @override
  String toString() => message;
}
