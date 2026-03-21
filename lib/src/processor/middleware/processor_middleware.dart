import 'package:flncrawly/flncrawly.dart';

/// Intercepts the input (responses) and output (items/requests) of a [Processor].
///
/// Corresponds to "Spider Middleware" in Scrapy.
abstract class ProcessorMiddleware<
  T,
  Req extends Request,
  Res extends Response
> {
  const ProcessorMiddleware();

  /// Intercepts and transforms the stream of initial seed requests.
  Stream<Req> onStart(Stream<Req> seeds) => seeds;

  /// Called before the response enters the processor's Parse logic.
  ///
  /// Use this to ignore responses, modify them, or track session state.
  Future<void> onInput(Res response) async {}

  /// Intercepts and transforms the stream of results yielded by the processor.
  ///
  /// This can be used to filter items, add metadata to followed requests,
  /// or drop requests based on a policy (e.g., Depth).
  Stream<PCResult<T, Req>> onOutput(
    Res response,
    Stream<PCResult<T, Req>> result,
  ) => result;

  /// Handles exceptions raised by the processor or an [onOutput] hook.
  ///
  /// Return a new stream of [PCResult]s to handle the error, or `null`
  /// to continue letting the next middleware's [onException] handle it.
  Stream<PCResult<T, Req>>? onException(Res response, Object exception) => null;

  /// Cleanup logic called when the engine stops.
  void close() {}
}
