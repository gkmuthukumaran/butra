// config.dart

class APIConfig {
  // Base URL for your API
  // static const String baseUrl = "https://api.example.com/";
  // static const String baseUrl = "http://192.168.1.2:5000/api";
  // static const String baseUrl = "http://13.214.131.66/api";
  // static const String baseUrl = "http://127.0.0.1:5000/api";
  // static const String baseUrl = "http://172.20.10.3:5000/api";
  static const String baseUrl = "https://www.hmbweighbridge.com/api";

  // Endpoints
  static const String loginEndpoint = "auth/login";
  static const String registerEndpoint = "auth/register";
  static const String fetchDataEndpoint = "data/fetch";
  static const String bookingEndpoint = "bookings";
  static const String profileEndpoint = "user/profile";

  // You can add more endpoints as needed
}
