/// A collection of common browser User-Agent strings.
abstract final class UserAgents {
  /// Chrome on Windows
  static const String windowsChrome = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  /// Chrome on macOS
  static const String macChrome = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  /// Safari on macOS
  static const String macSafari = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15';

  /// Firefox on Windows
  static const String windowsFirefox = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0';

  /// iPhone Safari
  static const String iphoneSafari = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1';

  /// Android Chrome
  static const String androidChrome = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  /// Returns a random User-Agent from the common list.
  static String random() {
    final list = [windowsChrome, macChrome, macSafari, windowsFirefox, iphoneSafari, androidChrome];
    return (list..shuffle()).first;
  }
}
