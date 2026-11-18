/// Hierarki exception aplikasi (Error Handling + Inheritance).
class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class RoomUnavailableException extends AppException {
  RoomUnavailableException(super.message);
}

class InvalidOperationException extends AppException {
  InvalidOperationException(super.message);
}

class DatabaseException extends AppException {
  DatabaseException(super.message);
}
