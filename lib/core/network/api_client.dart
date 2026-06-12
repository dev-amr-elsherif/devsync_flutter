import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiClient {
  ApiClient._();

  static Dio? _githubClient;
  static Dio? _baseClient;

  static Dio get github {
    _githubClient ??= _buildClient(
      baseUrl: ApiConstants.githubApiBase,
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    return _githubClient!;
  }

  static Dio get base {
    _baseClient ??= _buildClient(baseUrl: '');
    return _baseClient!;
  }

  static Dio _buildClient({
    required String baseUrl,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
    );

    dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(dio),
    ]);

    return dio;
  }

  /// Sets the GitHub Bearer token after OAuth login
  static void setGitHubToken(String token) {
    github.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clears auth headers (on sign-out)
  static void clearTokens() {
    github.options.headers.remove('Authorization');
  }
}

// ─── Logging Interceptor ──────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // Only log in debug mode
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERROR] ${err.response?.statusCode} ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

// ─── Retry Interceptor ────────────────────────────────────────────────────────
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int _maxRetries = 2;

  _RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout);

    if (shouldRetry) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      await Future.delayed(Duration(seconds: retryCount + 1));
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // fall through to default handler
      }
    }

    handler.next(err);
  }
}
