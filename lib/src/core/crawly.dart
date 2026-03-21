import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/dispatcher/dispatcher.dart';
import 'package:flncrawly/src/dispatcher/priority_dispatcher.dart';
import 'package:flncrawly/src/downloader/downloader.dart';
import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/downloader/middleware/h1_downloader_middleware.dart';
import 'package:flncrawly/src/pipeline/pipeline.dart';
import 'package:flncrawly/src/processor/middleware/processor_middleware.dart';
import 'package:flncrawly/src/processor/processor.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';

/// A fluent builder for configuring and running a crawl.
/// [T] is the type of extracted items.
/// [Req] is the type of request used.
/// [Res] is the type of response received.
class Crawly<T, Req extends Request, Res extends Response> {
  final Processor<T, Req, Res> _processor;

  Dispatcher<Req>? _dispatcher;
  Downloader<Req, Res>? _downloader;
  final List<DownloaderMiddleware<Req, Res>> _downloaderMiddlewares = [];
  final List<ProcessorMiddleware<T, Req, Res>> _processorMiddlewares = [];
  final List<Pipeline<T>> _pipelines = [];

  /// Creates a new [Crawly] builder with the given [processor].
  Crawly(this._processor);

  /// Alias for constructor. Sets the core [Processor].
  static Crawly<T, Req, Res> withProcessor<
    T,
    Req extends Request,
    Res extends Response
  >(Processor<T, Req, Res> p) => Crawly<T, Req, Res>(p);

  /// Sets a custom [Dispatcher] (Scheduler).
  Crawly<T, Req, Res> withScheduler(Dispatcher<Req> d) {
    _dispatcher = d;
    return this;
  }

  /// Sets a custom [Downloader].
  Crawly<T, Req, Res> withDownloader(Downloader<Req, Res> d) {
    _downloader = d;
    return this;
  }

  /// Adds a [DownloaderMiddleware] to the downloader chain.
  Crawly<T, Req, Res> addDownloaderMiddleware(
    DownloaderMiddleware<Req, Res> m,
  ) {
    _downloaderMiddlewares.add(m);
    return this;
  }

  /// Adds a [ProcessorMiddleware] to the processor chain.
  Crawly<T, Req, Res> addProcessorMiddleware(
    ProcessorMiddleware<T, Req, Res> m,
  ) {
    _processorMiddlewares.add(m);
    return this;
  }

  /// Adds multiple [ProcessorMiddleware] items.
  Crawly<T, Req, Res> addProcessorMiddlewares(
    List<ProcessorMiddleware<T, Req, Res>> middlewares,
  ) {
    _processorMiddlewares.addAll(middlewares);
    return this;
  }

  /// Adds a [Pipeline] for post-processing extracted items.
  Crawly<T, Req, Res> addPipe(Pipeline<T> p) {
    _pipelines.add(p);
    return this;
  }

  /// Adds multiple [Pipeline] items.
  Crawly<T, Req, Res> addPipes(List<Pipeline<T>> pipes) {
    _pipelines.addAll(pipes);
    return this;
  }

  /// Builds the [Engine] based on the current configuration.
  Engine<T, Req, Res> build() {
    final downloader =
        _downloader ??
        Downloader(
          middlewares: [..._downloaderMiddlewares, H1DownloaderMiddleware()],
        );

    return Engine<T, Req, Res>(
      dispatcher: _dispatcher ?? PriorityDispatcher<Req>(),
      downloader: downloader,
      processor: _processor,
      processorMiddlewares: _processorMiddlewares,
      pipelines: _pipelines,
    );
  }

  /// Builds and runs the crawl.
  Future<void> run() async => build().start();
}
