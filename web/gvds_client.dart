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

  static String _buildQuery(Map<String, dynamic> parameters) {
    if (parameters == null || parameters.isEmpty) {
      return "";
    }

    // inspired by Uri._makeQuery
    StringBuffer result = new StringBuffer();
    bool first = true;
    parameters.forEach((String key, value) {
      result.write(first ? "?" : "&");
      first = false;
      result.write(Uri.encodeQueryComponent(key));
      if (value != null) {
        result.write("=");
        result.write(Uri.encodeQueryComponent(value.toString()));
      }
    });
    return result.toString();
  }

  Future<GvdsResponse> getUserInfo() {
    return _request("GET", "user/current");
  }

  Future<GvdsResponse> getTypes() {
    return _request("GET", "type");
  }

  Future<GvdsResponse> _getDataInternal(String type, String subPath, {int
      first, int max}) {
    String typeEncoded = Uri.encodeComponent(type);
    Map<String, dynamic> parameters = {};
    if (first != null) {
      parameters["first"] = first;
    }
    if (max != null) {
      parameters["max"] = max;
    }
    String query = _buildQuery(parameters);
    return _request("GET", "data/$typeEncoded$subPath$query");
  }

  Future<GvdsResponse> getData(String type, {int first, int max}) {
    return _getDataInternal(type, "/", first: first, max: max);
  }

  Future<GvdsResponse> getDataCount(String type) {
    return _getDataInternal(type, "/count");
  }

}
