import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'constants.dart';

/// Lightweight HTTP client used by location providers to call external APIs.
///
/// Wraps [http.Client] and applies a configurable timeout to every request.
class GeoApiClient {
  /// Creates a [GeoApiClient].
  ///
  /// [httpTimeoutMs] — request timeout in milliseconds (default 8 s).
  /// [client] — optional custom [http.Client] for testing.
  GeoApiClient({
    int httpTimeoutMs = kDefaultHttpTimeoutMs,
    http.Client? client,
  })  : _timeoutMs = httpTimeoutMs,
        _client = client ?? http.Client();

  final int _timeoutMs;
  final http.Client _client;

  Duration get _timeout => Duration(milliseconds: _timeoutMs);

  /// Performs a GET request and returns the decoded JSON body.
  ///
  /// Returns `null` on any network error or non-2xx status.
  Future<Map<String, dynamic>?> get(String url) async {
    try {
      final response =
          await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        developer.log(
          'GET $url → HTTP ${response.statusCode}',
          name: kLogName,
        );
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      developer.log('GET $url failed: $e', name: kLogName);
      return null;
    }
  }

  /// Performs a POST request with a JSON body and returns the decoded
  /// JSON response body.
  ///
  /// Returns `null` on any network error or non-2xx status.
  Future<Map<String, dynamic>?> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        developer.log(
          'POST $url → HTTP ${response.statusCode}: ${response.body}',
          name: kLogName,
        );
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      developer.log('POST $url failed: $e', name: kLogName);
      return null;
    }
  }

  /// Closes the underlying HTTP client and releases resources.
  void dispose() => _client.close();
}
