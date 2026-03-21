import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The engine for downloading requests via a chain of middlewares.
/// At least one middleware in the chain must produce a [ProxyResponse]
/// (usually the last one acting as a fetcher).
class Downloader<Req extends Request, Res extends Response> {
  /// The engine instance running this downloader.
  late final Engine engine;
  
  /// The list of middlewares configured for this downloader.
  final List<DownloaderMiddleware<Req, Res>> middlewares;

  Downloader({this.middlewares = const []});

  /// Entry point for the engine to download a request.
  /// Orchestrates the [processRequest] chain (Top-to-Bottom).
  Future<DMResult<Req, Res>> download(Req req) async {
    var currentRequest = req;

    for (int i = 0; i < middlewares.length; i++) {
      try {
        final result = await middlewares[i].processRequest(currentRequest);

        switch (result) {
          case NextRequest(:final request):
            currentRequest = request;
          case RescheduleRequest() || ReportError() || IgnoreResult():
            return result;
          case ProxyResponse(:final response):
            // Response produced by a middleware.
            // Start the response processing chain bottom-to-top from this middleware.
            return _handleResponse(currentRequest, response, i);
        }
      } catch (e) {
        // Exception in processRequest: start exception chain from this middleware backwards.
        return _handleException(currentRequest, e, i);
      }
    }

    // No middleware produced a response or error.
    return DMResult.error(
      StateError(
        'No middleware handled the request to ${currentRequest.url}. '
        'At least one middleware (e.g. a fetcher) must return a ProxyResponse.',
      ),
    );
  }

  /// Orchestrates [processResponse] chain (Bottom-to-Top).
  Future<DMResult<Req, Res>> _handleResponse(
    Req req,
    Res res,
    int startIndex,
  ) async {
    var currentResponse = res;

    // Process backwards from the middleware that produced/last-saw the response.
    for (int i = startIndex; i >= 0; i--) {
      try {
        final result = await middlewares[i].processResponse(
          req,
          currentResponse,
        );

        switch (result) {
          case ProxyResponse(:final response):
            currentResponse = response;
          case RescheduleRequest() || ReportError() || IgnoreResult():
            return result;
          case NextRequest():
            throw StateError('processResponse must not return NextRequest');
        }
      } catch (e) {
        // If a response handler fails, it triggers the remaining exception chain bottom-to-top.
        return _handleException(req, e, i - 1);
      }
    }
    return DMResult.response(currentResponse);
  }

  /// Orchestrates [processException] chain (Bottom-to-Top).
  Future<DMResult<Req, Res>> _handleException(
    Req req,
    Object error,
    int startIndex,
  ) async {
    var currentError = error;

    for (int i = startIndex; i >= 0; i--) {
      try {
        final result = await middlewares[i].processException(req, currentError);

        switch (result) {
          case ReportError(:final error):
            currentError = error;
          case ProxyResponse(:final response):
            // Exception handled, start response chain from this point upwards.
            return _handleResponse(req, response, i - 1);
          case RescheduleRequest() || IgnoreResult():
            return result;
          case NextRequest():
            throw StateError(
              'processException must return ReportError, ProxyResponse, Reschedule, or Ignore',
            );
        }
      } catch (e) {
        currentError = e; // Replace current error with the one from the handler
      }
    }
    return DMResult.error(currentError);
  }

  /// Closes all configured middlewares.
  void close() {
    for (final m in middlewares) {
      m.close();
    }
  }
}
