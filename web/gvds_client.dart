library gvds_client;

import "dart:html";
import "dart:async";
import 'dart:convert' show JSON;
import "package:crypto/crypto.dart";
import "package:utf/utf.dart";


class GvdsResponse {
  final bool success;
  final Map<String, dynamic> data;
  final HttpRequest request;

  static Map<String, dynamic> _extractData(HttpRequest request) {
    String contentType = request.responseHeaders["content-type"];
    if (contentType != null && contentType.startsWith("application/json")) {
      return JSON.decode(request.responseText);
    } else {
      return null;
    }
  }

  GvdsResponse(this.success, this.data, this.request);

  GvdsResponse.autoExtract(bool success, HttpRequest request): this(success,
      _extractData(request), request);
}

class GvdsClient {
  final String baseUrl;
  final String user;
  final String pass;

  GvdsClient(String baseUrl, this.user, this.pass): this.baseUrl =
      baseUrl.endsWith("/") ? baseUrl : "$baseUrl/";

  Map _getHeaders() {
    // TODO: cache?
    String auth = CryptoUtils.bytesToBase64(encodeUtf8("$user:$pass"));
    return {
      "Accept": "application/json",
      "Authorization": "Basic $auth"
    };
  }

  Future<GvdsResponse> _handleRequest(Future<HttpRequest> future) {
    return future.then((HttpRequest request) {
      return new GvdsResponse.autoExtract(true, request);
    }, onError: (Event event) {
      throw new GvdsResponse.autoExtract(false, event.target);
    });
  }

  Future<GvdsResponse> _request(String method, String path, [Map<String,
      dynamic> data]) {
    String json = data == null ? null : JSON.encode(data);
    return _handleRequest(HttpRequest.request("$baseUrl$path", method: method,
        requestHeaders: _getHeaders(), sendData: json));
  }

  Future<GvdsResponse> getUserInfo() {
    return _request("GET", "user/current");
  }

}
