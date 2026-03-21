import 'dart:async';
import 'dart:math';

import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/request/request.dart';

/// The default [Dispatcher] implementation with concurrency control and prioritization.
class PriorityDispatcher<Req extends Request> extends Dispatcher<Req> {
  final int maxRetries;
  final int maxConcurrent;

  int _retryingCount = 0;
  int _concurrentCount = 0;

  final Set<String> _seen = {};
  final List<Req> _queue = [];

  final StreamController<Req> _controller = StreamController<Req>();
  final StreamController<DispatcherEvent<Req>> _eventController =
      StreamController.broadcast();

  PriorityDispatcher({this.maxRetries = 3, this.maxConcurrent = 10});

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
