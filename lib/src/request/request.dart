/// Represents an HTTP request to be executed by the crawler engine.
class Request {
  /// The target URL of the request.
  final Uri url;

  /// The HTTP method to use (e.g., 'GET', 'POST'). Defaults to 'GET'.
  final String method;

  /// Custom HTTP headers to include in the request.
  final Map<String, String> headers;

  /// HTTP cookies to include in the request, sent via the 'Cookie' header.
  final Map<String, String> cookies;

  /// The raw request body as bytes. Useful for POST or PUT requests.
  final List<int>? body;

  /// The character encoding for the request.
  final String? encoding;

  /// The scheduling priority. Higher numbers are dispatched first.
  final int priority;

  /// User-defined metadata associated with this request, carried over to the response.
  final Map<String, dynamic> meta;

  /// The number of times this request has been retried.
  final int retries;

  /// If true, the dispatcher will skip duplicate URL filtering for this request.
  final bool dontFilter;

  /// Creates a new [Request] instance.
  const Request({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.cookies = const {},
    this.body,
    this.encoding,
    this.priority = 0,
    this.meta = const {},
    this.retries = 0,
    this.dontFilter = false,
  });

  /// Unique fingerprint for deduplication.
  /// Includes [method], [url], and a hash of the [body] if present.
  String get fingerprint {
    if (body == null || body!.isEmpty) return '$method:$url';
    return '$method:$url:${body.hashCode}';
  }

  /// Creates a copy of this request with an incremented [retries] count.
  Request nextRetry() => copyWith(retries: retries + 1);

  /// Creates a copy of this request with the specified fields updated.
  Request copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    Map<String, String>? cookies,
    List<int>? body,
    String? encoding,
    int? priority,
    Map<String, dynamic>? meta,
    int? retries,
    bool? dontFilter,
  }) {
    return Request(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      cookies: cookies ?? this.cookies,
      body: body ?? this.body,
      encoding: encoding ?? this.encoding,
      priority: priority ?? this.priority,
      meta: meta ?? this.meta,
      retries: retries ?? this.retries,
      dontFilter: dontFilter ?? this.dontFilter,
    );
  }

  @override
  String toString() => '[$method] $url';
}
