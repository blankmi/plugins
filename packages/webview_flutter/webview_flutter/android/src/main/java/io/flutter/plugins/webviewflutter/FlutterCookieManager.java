// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

class FlutterCookieManager implements MethodCallHandler {
  private final MethodChannel methodChannel;

  FlutterCookieManager(BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "plugins.flutter.io/cookie_manager");
    methodChannel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case "clearCookies":
        clearCookies(result);
        break;
      case "getCookies":
        getCookies(methodCall.<String>argument("url"), result);
        break;
      default:
        result.notImplemented();
    }
  }

  void dispose() {
    methodChannel.setMethodCallHandler(null);
  }

  private static void getCookies(final String url, final Result result) {
    CookieManager cookieManager = CookieManager.getInstance();
    final List<Map<String, Object>> cookieListMap = new ArrayList<>();

    String cookiesString = cookieManager.getCookie(url);

    if (cookiesString != null) {
      String[] cookies = cookiesString.split(";");
      for (String cookie : cookies) {
        String[] nameValue = cookie.split("=", 2);
        Map<String, Object> cookieMap = new HashMap<>();
        cookieMap.put("name", nameValue[0].trim());
        cookieMap.put("value", nameValue[1].trim());
        cookieListMap.add(cookieMap);
      }
    }
    result.success(cookieListMap);
  }

  private static void clearCookies(final Result result) {
    CookieManager cookieManager = CookieManager.getInstance();
    final boolean hasCookies = cookieManager.hasCookies();
    if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      cookieManager.removeAllCookies(
          new ValueCallback<Boolean>() {
            @Override
            public void onReceiveValue(Boolean value) {
              result.success(hasCookies);
            }
          });
    } else {
      cookieManager.removeAllCookie();
      result.success(hasCookies);
    }
  }
}
