import 'dart:typed_data';

import 'package:flncrawly/src/request/request.dart';

/// Base class for all crawl responses.
abstract class Response {
  /// The final URL reached after any redirections.
  final Uri url;

  /// The HTTP status code of the response.
  final int status;

  /// The response headers received from the server.
  final Map<String, dynamic> headers;

  /// The raw response body as bytes.
  final Uint8List body;

  /// The original [Request] that triggered this response.
  final Request request;

  /// Metadata carried over from the original request or added during downloading.
  final Map<String, dynamic> meta;

  /// Creates a new [Response] instance.
  const Response({
    required this.url,
    required this.status,
    required this.headers,
    required this.body,
    required this.request,
    required this.meta,
  });

  /// Returns true if the status code indicates success (200-299).
  bool isSuccess() => status >= 200 && status < 300;

  /// Returns true if the status code indicates a redirection (300-399).
  bool isRedirect() => status >= 300 && status < 400;

  /// Returns true if the status code indicates a client or server error (>= 400).
  bool isError() => status >= 400;

  /// Joins the given [path] with the current response URL.
  Uri urljoin(String path) => url.resolve(path);

  /// Helper to create a new [Request] following a relative or absolute URL.
  /// Resolves the given [url] against the current response's [url].
  Request follow(String path, {Map<String, dynamic>? meta}) {
    return request.copyWith(url: urljoin(path), meta: meta ?? this.meta);
  }
}
