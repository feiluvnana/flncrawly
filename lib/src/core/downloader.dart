import 'dart:convert';

import 'package:flncrawly/src/core/engine.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/request/user_agents.dart';
import 'package:flncrawly/src/response/html_response.dart';
import 'package:flncrawly/src/response/json_response.dart';
import 'package:flncrawly/src/response/response.dart';
import 'package:flncrawly/src/response/text_response.dart';
import 'package:flncrawly/src/response/xml_response.dart';
import 'package:http/http.dart' as http;

abstract class Downloader<Req extends Request, Res extends Response> {
  /// The engine instance running this downloader.
  late final Engine engine;

  Future<Res> download(Req req);
}

class DefaultDownloader<Req extends Request, Res extends Response>
    extends Downloader<Req, Res> {
  final http.Client _client = http.Client();
  final Map<String, String> _cookies = {};

  void clearCookies() => _cookies.clear();

  @override
  Future<Res> download(Req req) async {
    final hreq = http.Request(req.method, req.url);
    if (!req.headers.containsKey('User-Agent')) {
      hreq.headers['User-Agent'] = UserAgents.random();
    }
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

    if (contentType.contains('json')) {
      return JsonResponse(
            url: url,
            status: status,
            headers: headers,
            body: body,
            request: req,
            meta: meta,
          )
          as Res;
    }

    if (contentType.contains('html')) {
      return HtmlResponse(
            url: url,
            status: status,
            headers: headers,
            body: body,
            request: req,
            meta: meta,
          )
          as Res;
    }

    if (contentType.contains('xml')) {
      return XmlResponse(
            url: url,
            status: status,
            headers: headers,
            body: body,
            request: req,
            meta: meta,
          )
          as Res;
    }

    return TextResponse(
          url: url,
          status: status,
          headers: headers,
          body: body,
          request: req,
          meta: meta,
        )
        as Res;
  }

  void _updateCookies(String sc) {
    for (final p in sc.split(',')) {
      final nv = p.split(';').first.trim();
      final i = nv.indexOf('=');
      if (i != -1) _cookies[nv.substring(0, i)] = nv.substring(i + 1);
    }
  }
}
