import 'package:flncrawly/flncrawly.dart';

/// The result of a [Processor]'s work.
/// [T] is the type of item extracted.
/// [Req] is the type of [Request] being followed or retried.
sealed class Result<T, Req extends Request> {
  const Result();

  /// Emits an extracted data item.
  factory Result.item(T item) = Item<T, Req>;

  /// Requests the engine to crawl a new [Request].
  factory Result.follow(Req req) = Follow<T, Req>;

  /// Commands the engine to stop the crawl.
  factory Result.finish() = Finish<T, Req>;

  /// Requests the engine to retry a [Request].
  factory Result.retry(Req req) = Retry<T, Req>;

  /// Reports an error encountered during processing.
  factory Result.error(Object e, [StackTrace? s]) = Error<T, Req>;
}

/// A wrapper for an extracted data item.
class Item<T, Req extends Request> extends Result<T, Req> {
  final T item;
  const Item(this.item);
}

/// An instruction to crawl a new [Request].
class Follow<T, Req extends Request> extends Result<T, Req> {
  final Req request;
  const Follow(this.request);
}

/// An instruction to stop the engine.
class Finish<T, Req extends Request> extends Result<T, Req> {
  const Finish();
}

/// An instruction to retry a failed [Request].
class Retry<T, Req extends Request> extends Result<T, Req> {
  final Req request;
  const Retry(this.request);
}

/// An instruction reporting a processing error.
class Error<T, Req extends Request> extends Result<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  const Error(this.error, [this.stackTrace]);
}

/// Defines how to extract items and instructions from a crawl response.
abstract class Processor<T, Req extends Request, Res extends Response> {
  /// The engine instance running this processor.
  late final Engine<T, Req, Res> engine;

  /// The entry points for this processor.
  List<Req> get seeds => [];

  /// Middlewares that can transform the response before processing.
  List<ProcessorMiddleware<T, Req, Res>> get middlewares => [];

  /// Processes the [Response] and yields extraction results.
  Stream<Result<T, Req>> process(Res res);
}

/// Defines a middleware that can transform or monitor a response before it is processed.
abstract class ProcessorMiddleware<
  T,
  Req extends Request,
  Res extends Response
> {
  const ProcessorMiddleware();

  /// Transforms the [response] before it reaches the processor.
  Future<Res> handle(Res response);
}

/// A basic processor that yields no output.
class DefaultProcessor<T, Req extends Request, Res extends Response>
    extends Processor<T, Req, Res> {
  DefaultProcessor();

  @override
  Stream<Result<T, Req>> process(Res res) async* {}
}
