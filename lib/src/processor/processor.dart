import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// The result of a [Processor]'s extraction work.
/// [T] is the type of item extracted.
/// [Req] is the type of [Request] being followed or retried.
sealed class PCResult<T, Req extends Request> {
  const PCResult();

  /// Emits an extracted data item to be handled by the pipeline.
  factory PCResult.item(T item) = Item<T, Req>;

  /// Requests the engine to crawl a new [Request] found in the current page.
  factory PCResult.follow(Req req) = Follow<T, Req>;

  /// Commands the engine to stop the crawl immediately.
  factory PCResult.finish() = Finish<T, Req>;

  /// Requests the engine to retry the current [Request], possibly with a delay.
  factory PCResult.retry(Req req) = Retry<T, Req>;

  /// Reports an error encountered during extraction or processing.
  factory PCResult.error(Object e, [StackTrace? s]) = Error<T, Req>;
}

/// A wrapper for an extracted data item.
class Item<T, Req extends Request> extends PCResult<T, Req> {
  final T item;
  const Item(this.item);
}

/// An instruction to crawl a new [Request].
class Follow<T, Req extends Request> extends PCResult<T, Req> {
  final Req request;
  const Follow(this.request);
}

/// An instruction to stop the engine.
class Finish<T, Req extends Request> extends PCResult<T, Req> {
  const Finish();
}

/// An instruction to retry a failed [Request].
class Retry<T, Req extends Request> extends PCResult<T, Req> {
  final Req request;
  const Retry(this.request);
}

/// An instruction reporting a processing error.
class Error<T, Req extends Request> extends PCResult<T, Req> {
  final Object error;
  final StackTrace? stackTrace;
  const Error(this.error, [this.stackTrace]);
}

/// Defines the core logic for a crawl by specifying how to extract items
/// and discovery instructions from a response.
///
/// Corresponds to a "Spider" in other crawling frameworks.
abstract class Processor<T, Req extends Request, Res extends Response> {
  /// The engine instance running this processor.
  late final Engine<T, Req, Res> engine;

  /// The entry points (initial URLs) for this crawl.
  List<Req> get seeds => [];

  /// Processes the [Response] and yields extraction results asynchronously.
  ///
  /// Use `yield Result.item(data)` to output data, and `yield Result.follow(req)`
  /// to discover new links.
  Stream<PCResult<T, Req>> process(Res res);

  /// Cleanup logic called when the engine stops.
  void close() {}
}
