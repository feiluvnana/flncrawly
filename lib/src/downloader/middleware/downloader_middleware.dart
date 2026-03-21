import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// Represents the result of a [DownloaderMiddleware] operation.
sealed class DMResult<Req extends Request, Res extends Response> {
  const DMResult();

  /// Pass the request/response to the next middleware in the chain.
  factory DMResult.next(Req request) = NextRequest<Req, Res>;

  /// Return a final response immediately, bypassing/continuing the chain.
  factory DMResult.response(Res response) = ProxyResponse<Req, Res>;

  /// Requests the engine to reschedule the [Request] to be downloaded later.
  factory DMResult.reschedule(Req request) = RescheduleRequest<Req, Res>;

  /// Signal that an error occurred while downloading or processing the request.
  factory DMResult.error(Object error, [StackTrace? stackTrace]) =
      ReportError<Req, Res>;

  /// Commands the downloader to ignore this request and result entirely.
  factory DMResult.ignore() = IgnoreResult<Req, Res>;
}

/// A result that tells the downloader to continue with the [request].
final class NextRequest<Req extends Request, Res extends Response>
    extends DMResult<Req, Res> {
  final Req request;
  const NextRequest(this.request);
}

/// A result that provides a completed [response].
final class ProxyResponse<Req extends Request, Res extends Response>
    extends DMResult<Req, Res> {
  final Res response;
  const ProxyResponse(this.response);
}

/// A result that triggers a requeue of the [request].
final class RescheduleRequest<Req extends Request, Res extends Response>
    extends DMResult<Req, Res> {
  final Req request;
  const RescheduleRequest(this.request);
}

/// A result that reports an [error].
final class ReportError<Req extends Request, Res extends Response>
    extends DMResult<Req, Res> {
  final Object error;
  final StackTrace? stackTrace;
  const ReportError(this.error, [this.stackTrace]);
}

/// A result that instructs the engine to silently drop the request.
final class IgnoreResult<Req extends Request, Res extends Response>
    extends DMResult<Req, Res> {
  const IgnoreResult();
}

/// A component that intercepts [Request] objects before they are fetched,
/// or [Response] results after they are downloaded.
/// 
/// Used for tasks like User-Agent rotation, proxying, caching, or retry logic.
abstract class DownloaderMiddleware<Req extends Request, Res extends Response> {
  const DownloaderMiddleware();

  /// Called before each request goes through the downloading logic (Top-to-Bottom).
  /// 
  /// Return [DMResult.next] to continue the chain, or [DMResult.response] 
  /// to provide an immediate response (bypassing the network/fetcher).
  Future<DMResult<Req, Res>> processRequest(Req req) async => DMResult.next(req);

  /// Called after a response is downloaded or provided by a middleware (Bottom-to-Top).
  /// 
  /// Return [DMResult.response] to continue the chain, or other [DMResult]s 
  /// to reschedule or drop the request.
  Future<DMResult<Req, Res>> processResponse(Req req, Res res) async =>
      DMResult.response(res);

  /// Called when a downloader middleware raises an exception (Bottom-to-Top).
  /// 
  /// Return [DMResult.response] to recover from the exception, or 
  /// [DMResult.error] to continue the exception chain.
  Future<DMResult<Req, Res>> processException(Req req, Object exception) async =>
      DMResult.error(exception);

  /// Cleanup logic called when the engine stops.
  void close() {}
}
