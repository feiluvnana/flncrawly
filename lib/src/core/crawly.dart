import 'package:flncrawly/src/core/dispatcher.dart';
import 'package:flncrawly/src/core/downloader.dart';
import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/core/pipeline.dart';
import 'package:flncrawly/src/core/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// A fluent builder for configuring and running a crawl.
class Crawly<T, Req extends Request, Res extends Response> {
  Dispatcher<Req>? _dispatcher;
  Downloader<Req, Res>? _downloader;
  Processor<T, Req, Res>? _processor;
  final List<Pipeline<T>> _pipelines = [];

  /// Sets a custom [Dispatcher].
  Crawly<T, Req, Res> dispatcher(Dispatcher<Req> d) {
    _dispatcher = d;
    return this;
  }

  /// Sets a custom [Downloader].
  Crawly<T, Req, Res> downloader(Downloader<Req, Res> d) {
    _downloader = d;
    return this;
  }

  /// Sets the [Processor].
  Crawly<T, Req, Res> processor(Processor<T, Req, Res> p) {
    _processor = p;
    return this;
  }

  /// Adds a [Pipeline].
  Crawly<T, Req, Res> pipe(Pipeline<T> p) {
    _pipelines.add(p);
    return this;
  }

  /// Sets multiple [pipelines].
  Crawly<T, Req, Res> pipeAll(List<Pipeline<T>> pipes) {
    _pipelines.addAll(pipes);
    return this;
  }

  /// Builds the engine.
  Engine<T, Req, Res> build() => Engine<T, Req, Res>(
    dispatcher: _dispatcher ?? DefaultDispatcher<Req>(),
    downloader: _downloader ?? DefaultDownloader(),
    processor: _processor ?? DefaultProcessor<T, Req, Res>(),
    pipelines: _pipelines,
  );

  /// Configures (optionally) and runs the crawl using a [Processor].
  Future<void> run([Processor<T, Req, Res>? p]) async {
    if (p != null) processor(p);
    return build().start();
  }
}
