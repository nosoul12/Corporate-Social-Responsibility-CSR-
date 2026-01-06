import 'package:dio/dio.dart';
import 'package:animal_rescue_app/core/config/backend_config.dart';
import 'package:animal_rescue_app/core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio? _dio;
  String? _token;
  Future<void> Function()? _onUnauthorized;
  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized && _dio != null) return;
    initialize();
  }

  void initialize() {
    if (_initialized && _dio != null) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: BackendConfig.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          final fullUrl = '${options.baseUrl}${options.path}';
          print('[API Request] ${options.method} $fullUrl');
          if (options.data != null && options.data is! FormData) {
            print('[API Request Body] ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '[API Response] ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final errorMessage =
              error.response?.data?['message'] ?? error.message;
          final errorData = error.response?.data;

          print(
              '[API Error] ${error.requestOptions.method} ${error.requestOptions.path}');
          print('[API Error] Status: $statusCode');
          print('[API Error] Message: $errorMessage');
          if (errorData != null) {
            print('[API Error] Data: $errorData');
          }

          // Log CORS errors specifically
          if (error.type == DioExceptionType.unknown &&
              error.message?.contains('CORS') == true) {
            print(
                '[API Error] CORS ISSUE DETECTED - Check backend CORS configuration');
          }

          if (statusCode == 401 && _onUnauthorized != null) {
            print('[API Error] 401 Unauthorized - Triggering logout');
            await _onUnauthorized!.call();
          }
          handler.next(error);
        },
      ),
    );
    _initialized = true;
  }

  void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  void setAuthToken(String token) {
    _token = token;
  }

  void clearAuthToken() {
    _token = null;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    _ensureInitialized();
    try {
      final response = await _dio!.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createCase({
    required String title,
    required String description,
    required String type,
    required String severity,
    required double latitude,
    required double longitude,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    _ensureInitialized();
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageFilename,
        ),
        'title': title,
        'description': description,
        'type': type,
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await _dio!.post(
        '/cases',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String role,
    String? phone,
  ) async {
    _ensureInitialized();
    try {
      final response = await _dio!.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null) 'phone': phone,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    _ensureInitialized();
    try {
      final response = await _dio!.get('/auth/me');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Case endpoints
  Future<List<Map<String, dynamic>>> getCases() async {
    _ensureInitialized();
    try {
      final response = await _dio!.get('/cases');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCase(String caseId) async {
    _ensureInitialized();
    try {
      final response = await _dio!.get('/cases/$caseId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCase(
    String caseId,
    Map<String, dynamic> caseData,
  ) async {
    _ensureInitialized();
    try {
      final response = await _dio!.put('/cases/$caseId', data: caseData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Adoption endpoints
  Future<List<Map<String, dynamic>>> getAdoptions() async {
    _ensureInitialized();
    try {
      final response = await _dio!.get('/adoptions');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAdoption(
    Map<String, dynamic> adoptionData,
  ) async {
    _ensureInitialized();
    try {
      final response = await _dio!.post('/adoptions', data: adoptionData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAdoptionMultipart({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    _ensureInitialized();
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageFilename,
        ),
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      });

      final response = await _dio!.post(
        '/adoptions',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // NGO endpoints
  Future<List<Map<String, dynamic>>> getNearbyCases(
    double latitude,
    double longitude,
  ) async {
    _ensureInitialized();
    try {
      final response = await _dio!.get(
        '/ngo/nearby-cases',
        queryParameters: {'lat': latitude, 'lng': longitude},
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCaseStatus(
    String caseId,
    String status,
  ) async {
    _ensureInitialized();
    try {
      final response = await _dio!.patch(
        '/cases/$caseId/status',
        data: {'status': status},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteCase(String caseId) async {
    _ensureInitialized();
    try {
      await _dio!.delete('/cases/$caseId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAdoption(String adoptionId) async {
    _ensureInitialized();
    try {
      await _dio!.delete('/adoptions/$adoptionId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    // Try to extract error message from response body
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        // NestJS validation errors format
        if (data['message'] != null) {
          if (data['message'] is List) {
            return (data['message'] as List).join(', ');
          } else if (data['message'] is String) {
            return data['message'] as String;
          }
        }
        // Generic error message
        if (data['error'] != null && data['error'] is String) {
          return data['error'] as String;
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              return 'Bad request. Please check your input.';
            case 401:
              return 'Unauthorized. Please login again.';
            case 403:
              return 'Forbidden. You don\'t have permission to perform this action.';
            case 404:
              return 'Not found. The requested resource doesn\'t exist.';
            case 500:
              return 'Server error. Please try again later.';
            default:
              return 'HTTP Error: $statusCode';
          }
        }
        return 'Unknown error occurred.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your connection.';
      default:
        return 'Unknown error occurred.';
    }
  }
}
