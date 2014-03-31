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
    }).catchError((GvdsResponse error) {
      loginError = "Login failed: ${error.request.statusText}";
      logout();
    });
  }

  void logout() {
    loginState = "NOT_LOGGED_IN";
    client = null;
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
