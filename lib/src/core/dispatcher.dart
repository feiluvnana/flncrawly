import 'dart:async';
import 'dart:math';

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

/// The default [Dispatcher] implementation with concurrency control and prioritization.
class DefaultDispatcher<Req extends Request> extends Dispatcher<Req> {
  final int maxRetries;
  final int maxConcurrent;

  int _retryingCount = 0;
  int _concurrentCount = 0;

  final Set<String> _seen = {};
  final List<Req> _queue = [];

  final StreamController<Req> _controller = StreamController<Req>();
  final StreamController<DispatcherEvent<Req>> _eventController =
      StreamController.broadcast();

  DefaultDispatcher({this.maxRetries = 3, this.maxConcurrent = 10});

  @override
  Stream<Req> get requests => _controller.stream;

  @override
  Stream<DispatcherEvent<Req>> get events => _eventController.stream;

  @override
  void push(Req req) {
    if (_controller.isClosed) return;
    if (!req.dontFilter && !_seen.add(req.fingerprint)) return;
    _eventController.add(DispatcherEvent(DispatcherEventType.enqueued, req));
    _enqueue(req);
  }

  @override
  void retry(Req req) {
    if (_controller.isClosed || req.retries >= maxRetries) return;
    _eventController.add(DispatcherEvent(DispatcherEventType.retrying, req));
    _retryingCount++;
    final delay = Duration(seconds: pow(2, req.retries).toInt());
    Future.delayed(delay, () {
      _retryingCount--;
      _enqueue(req.nextRetry() as Req);
    });
  }

  void _enqueue(Req req) {
    _queue.add(req);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    _dispatch();
  }

  void _dispatch() {
    if (_controller.isClosed) return;
    while (_queue.isNotEmpty && _concurrentCount < maxConcurrent) {
      final req = _queue.removeAt(0);
      _concurrentCount++;
      _eventController.add(
        DispatcherEvent(DispatcherEventType.dispatched, req),
      );
      _controller.add(req);
    }
  }

  @override
  void complete(Req req) {
    _concurrentCount--;
    _eventController.add(DispatcherEvent(DispatcherEventType.completed, req));
    if (_queue.isEmpty && _concurrentCount == 0 && _retryingCount == 0) {
      close();
    } else {
      _dispatch();
    }
  }

  @override
  void close() {
    if (!_controller.isClosed) {
      _controller.close();
      _eventController.close();
    }
  }
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
