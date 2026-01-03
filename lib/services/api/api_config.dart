class ApiConfig {
  // URL base del backend - API Móvil
  static const String baseUrl = 'https://app.emsinetsolut.com/api/movil';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
