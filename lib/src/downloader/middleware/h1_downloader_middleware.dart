import 'dart:convert';

import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:flncrawly/src/response/text_response.dart';
import 'package:http/http.dart' as http;

/// A downloader middleware that performs the actual network request using http/v1.
/// Usually placed at the end of the downloader middleware chain.
class H1DownloaderMiddleware<Req extends Request, Res extends Response>
    extends DownloaderMiddleware<Req, Res> {
  final http.Client _client = http.Client();
  final Map<String, String> _cookies = {};

  H1DownloaderMiddleware();

  void clearCookies() => _cookies.clear();

  @override
  Future<DMResult<Req, Res>> processRequest(Req req) async {
    try {
      final res = await _fetch(req);
      return DMResult.response(res);
    } catch (e, s) {
      return DMResult.error(e, s);
    }
  }

  Future<Res> _fetch(Req req) async {
    final hreq = http.Request(req.method, req.url);
    hreq.headers.addAll(req.headers);
    final cookies = {..._cookies, ...req.cookies};
    if (cookies.isNotEmpty) {
      hreq.headers['Cookie'] = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
    }
    if (req.encoding != null) {
      final codec = Encoding.getByName(req.encoding!);
      if (codec != null) hreq.encoding = codec;
    }
    if (req.body != null) hreq.bodyBytes = req.body!;

    final sres = await _client.send(hreq);
    final res = await http.Response.fromStream(sres);
    if (res.headers['set-cookie'] != null) {
      _updateCookies(res.headers['set-cookie']!);
    }
    final contentType = (res.headers['content-type'] ?? '').toLowerCase();
    final url = req.url, status = res.statusCode, headers = res.headers;
    final body = res.bodyBytes, meta = req.meta;
    final tres = TextResponse(
      url: url,
      status: status,
      headers: headers,
      body: body,
      request: req,
      meta: meta,
    );
    return switch (contentType) {
          'application/json' => tres.json,
          'application/xml' => tres.xml,
          'text/html' => tres.html,
          _ => tres,
        }
        as Res;
  }

  void _updateCookies(String sc) {
    for (final p in sc.split(',')) {
      final nv = p.split(';').first.trim();
      final nvLower = nv.toLowerCase();
      final i = nvLower.indexOf('=');
      if (i != -1) _cookies[nv.substring(0, i)] = nv.substring(i + 1);
    }
  }

  @override
  void close() => _client.close();
}
