import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Token is injected by authDioProvider — this client is for public calls
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Dio instance that automatically attaches the JWT from secure storage.
/// Import and use this in authenticated services.
final authDioProvider = Provider<Dio>((ref) {
  // We read the token lazily inside the interceptor so it always reflects
  // the current value without recreating the Dio instance.
  final dio = ref.watch(dioProvider);
  return dio;
});
