// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTCookieManager.h"

@implementation FLTCookieManager {
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTCookieManager *instance = [[FLTCookieManager alloc] init];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/cookie_manager"
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"clearCookies"]) {
    [self clearCookies:result];
  } else if ([[call method] isEqualToString:@"getCookies"]) {
      if (@available(iOS 11.0, *)) {
          [self getCookies:call result:result];
      } else {
          result([NSArray array]);
      }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)getCookies:(FlutterMethodCall *)call result:(FlutterResult)result API_AVAILABLE(ios(11.0)) {
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    WKHTTPCookieStore *cookieStore = dataStore.httpCookieStore;
    NSMutableArray<NSDictionary *> *cookieList = [NSMutableArray array];
    
    NSString *url = [[call arguments] valueForKey:@"url"];
    
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
        for (NSHTTPCookie *cookie in cookies) {
            if ([url rangeOfString:cookie.domain].location != NSNotFound) {
                NSDictionary *data = @{
                                       @"name":cookie.name,
                                       @"value":cookie.value,
                                       @"domain":cookie.domain,
                                       };
                
                [cookieList addObject:data];
            }
        }
        
        result(cookieList);
    }];
}


- (void)clearCookies:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    NSSet<NSString *> *websiteDataTypes = [NSSet setWithObject:WKWebsiteDataTypeCookies];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

    void (^deleteAndNotify)(NSArray<WKWebsiteDataRecord *> *) =
        ^(NSArray<WKWebsiteDataRecord *> *cookies) {
          BOOL hasCookies = cookies.count > 0;
          [dataStore removeDataOfTypes:websiteDataTypes
                        forDataRecords:cookies
                     completionHandler:^{
                       result(@(hasCookies));
                     }];
        };

    [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:deleteAndNotify];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cookies is not supported for Flutter WebViews prior to iOS 9.");
  }
}

@end
