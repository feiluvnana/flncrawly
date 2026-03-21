import 'package:flncrawly/src/downloader/middleware/downloader_middleware.dart';
import 'package:flncrawly/src/request/request.dart';
import 'package:flncrawly/src/request/user_agents.dart';
import 'package:flncrawly/src/response/response.dart';

/// A downloader middleware that ensures a User-Agent header is set for every request.
class UserAgentMiddleware<Req extends Request, Res extends Response>
    extends DownloaderMiddleware<Req, Res> {
  final String? fixedUserAgent;

  UserAgentMiddleware({this.fixedUserAgent});

  @override
  Future<DMResult<Req, Res>> processRequest(Req req) async {
    if (req.headers.containsKey('User-Agent')) {
      return DMResult.next(req);
    }

    final ua = fixedUserAgent ?? UserAgents.random();
    final newHeaders = {...req.headers, 'User-Agent': ua};
    return DMResult.next(req.copyWith(headers: newHeaders) as Req);
  }
}
