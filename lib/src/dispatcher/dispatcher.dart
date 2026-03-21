import 'dart:async';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';

/// Orchestrates the flow of requests between the scheduler and the engine.
abstract class Dispatcher<Req extends Request> {
  /// The engine instance running this dispatcher.
  late final Engine engine;

  /// A stream of internal dispatcher events for monitoring.
  Stream<DispatcherEvent<Req>> get events;

  /// A stream of requests ready to be downloaded.
  Stream<Req> get requests;

  /// Adds a new request to the crawling queue.
  void push(Req req);

  /// Alias for [push].
  void enqueue(Req req) => push(req);

  /// Schedules a request for retry with an appropriate backoff.
  void retry(Req req);

  /// Signals that a request has been processed, freeing up capacity.
  void complete(Req req);

  /// Closes the dispatcher and its associated streams.
  void close();
}

/// The types of events emitted by a [Dispatcher].
enum DispatcherEventType { enqueued, dispatched, retrying, completed }

/// An event tracked by the [Dispatcher].
class DispatcherEvent<Req extends Request> {
  final DispatcherEventType type;
  final Req request;
  final DateTime timestamp;

  DispatcherEvent(this.type, this.request) : timestamp = DateTime.now();

  @override
  String toString() => '${type.name.toUpperCase()}: ${request.url}';
}
