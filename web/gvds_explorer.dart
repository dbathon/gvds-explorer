library gvds_explorer;

import "dart:html";
import 'dart:async';
import 'dart:convert' show JSON;

import 'package:angular/angular.dart';
import 'package:di/di.dart';

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(targets: const [], override: '*')
import 'dart:mirrors';

import 'gvds_client.dart';


/**
 * TODO: use local storage to store user/pass/server
 */
@NgController(selector: "[gvds-explorer-ctrl]", publishAs: "c")
class AppController {
  static final String LOGIN_LOCAL_STORAGE_KEY = "gvds-explorer-login-data";

  String loginState = "NOT_LOGGED_IN";

  String gvdsBaseUrl;
  String loginUser;
  String loginPass;
  String loginError;

  GvdsClient client;

  int lastVersion;
  List<String> types;

  String type;

  int dataCount;
  List<Map<String, dynamic>> data;

  AppController() {
    restoreLoginData();
  }

  void saveLoginData() {
    window.localStorage[LOGIN_LOCAL_STORAGE_KEY] = JSON.encode({
      "baseUrl": gvdsBaseUrl,
      "user": loginUser,
    });
  }

  void restoreLoginData() {
    String data = window.localStorage[LOGIN_LOCAL_STORAGE_KEY];
    if (data != null) {
      var map = JSON.decode(data);
      gvdsBaseUrl = map["baseUrl"];
      loginUser = map["user"];
    }
  }

  void login() {
    loginState = "LOGGING_IN";
    loginError = null;

    client = new GvdsClient(gvdsBaseUrl, loginUser, loginPass);

    client.getUserInfo().then((GvdsResponse response) {
      lastVersion = response.data["version"].toInt();
      loginState = "LOGGED_IN";
      saveLoginData();

      refreshTypes();
    }).catchError((GvdsResponse error) {
      loginError = "Login failed: ${error.request.statusText}";
      logout();
    });
  }

  void logout() {
    loginState = "NOT_LOGGED_IN";
    client = null;
    lastVersion = null;
    types = null;
    type = null;
    dataCount = null;
    data = null;
  }

  void handleError(GvdsResponse error) {
    // TODO
    print("request error: ${error.request.statusText}, ${error.data}");
  }

  void refreshTypes() {
    client.getTypes().then((GvdsResponse response) {
      types = response.data["result"].map((Map item) => item["name"]).toList();
    }).catchError(handleError);
  }

  void selectType(String type) {
    this.type = type;
    fetchData();
  }

  void fetchData() {
    client.getDataCount(type).then((GvdsResponse response) {
      dataCount = response.data["result"].toInt();
    }).catchError(handleError);

    client.getData(type, max: 10).then((GvdsResponse response) {
      data = response.data["result"];
    }).catchError(handleError);
  }

}


class AppModule extends Module {
  AppModule() {
    type(AppController);
  }
}

void main() {
  ngBootstrap(module: new AppModule());
}
