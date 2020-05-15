import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

typedef DropboxProgressCallback = void Function(
    int currentBytes, int totalBytes);

class _CallbackInfo {
  int filesize;
  DropboxProgressCallback callback;

  _CallbackInfo(this.filesize, this.callback);
}

class Dropbox {
  static const MethodChannel _channel = const MethodChannel('dropbox');

  static int _callbackInt = 0;
  static Map<int, _CallbackInfo> _callbackMap = Map<int, _CallbackInfo>();

  /// Initialize dropbox library
  ///
  /// init() should be called only once.
  static Future<bool> init(String clientId, String key, String secret) async {
    _channel.setMethodCallHandler(_handleMethodCall);

    return await _channel.invokeMethod(
        'init', {'clientId': clientId, 'key': key, 'secret': secret});
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    // print('_handleMethodCall: ' + call.method);
    // print(call.arguments);
    var key = call.arguments[0];
    var bytes = call.arguments[1];

    if (_callbackMap.containsKey(key)) {
      final info = _callbackMap[key];
      if (info.callback != null) {
        info.callback(bytes, info.filesize);
      }
    }
  }

  /// Authorize using Dropbox app or web browser.
  ///
  /// Authorize using Dropbox app if it's installed. If not installed, it calls external web browser for authorization.
  /// When user authorizes, no feedback is available. call getAccessToken() to check if authorized.
  static Future<void> authorize() async {
    await _channel.invokeMethod('authorize');
  }

  /// Authorize with AccessToken
  ///
  /// use getAccessToken() to get Access Token after successful authorize().
  /// authorizeWithAccessToken() will authorize without user interaction if access token is valid.
  static Future<void> authorizeWithAccessToken(String accessToken) async {
    await _channel
        .invokeMethod('authorizeWithAccessToken', {'accessToken': accessToken});
  }

  // static Future<String> getAuthorizeUrl() async {
  //   return await _channel.invokeMethod('getAuthorizeUrl');
  // }

  // static Future<String> finishAuth(String code) async {
  //   return await _channel.invokeMethod('finishAuth', {'code': code});
  // }

  /// get Access Token after authorization.
  ///
  /// returns null before authorization.
  static Future<String> getAccessToken() async {
    return await _channel.invokeMethod('getAccessToken');
  }

  /// get account name
  static Future<String> getAccountName() async {
    return await _channel.invokeMethod('getAccountName');
  }

  /// get folder/file list for path.
  ///
  /// returns List<dynamic>. Use path='' for accessing root folder. List items are not sorted.
  static Future listFolder(String path) async {
    return await _channel.invokeMethod('listFolder', {'path': path});
  }

  /// get temporary link url for file
  ///
  /// returns url for accessing dropbox file.
  static Future<String> getTemporaryLink(String path) async {
    return await _channel.invokeMethod('getTemporaryLink', {'path': path});
  }

  /// upload local file in filepath to dropboxpath.
  ///
  /// filepath is local file path. dropboxpath should start with /.
  /// callback for monitoring progress : (uploadedBytes, totalBytes) { } (can be null)
  static Future upload(String filepath, String dropboxpath,
      DropboxProgressCallback callback) async {
    final fileSize = File(filepath).lengthSync();
    final key = ++_callbackInt;

    _callbackMap[key] = _CallbackInfo(fileSize, callback);

    final ret = await _channel.invokeMethod('upload',
        {'filepath': filepath, 'dropboxpath': dropboxpath, 'key': key});

    _callbackMap.remove(key);

    return ret;
  }
}
