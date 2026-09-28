/**
 * Modified MIT License
 *
 * Copyright 2023 OneSignal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * 2. All copies of substantial portions of the Software may only be used in
 * connection with services provided by OneSignal.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "./include/onesignal_flutter/OneSignalPlugin.h"
#import "./include/onesignal_flutter/OSFlutterCategories.h"
#import "./include/onesignal_flutter/OSFlutterDebug.h"
#import "./include/onesignal_flutter/OSFlutterInAppMessages.h"
#import "./include/onesignal_flutter/OSFlutterLiveActivities.h"
#import "./include/onesignal_flutter/OSFlutterLocation.h"
#import "./include/onesignal_flutter/OSFlutterNotifications.h"
#import "./include/onesignal_flutter/OSFlutterSession.h"
#import "./include/onesignal_flutter/OSFlutterUser.h"
#import <OneSignalOSCore/OneSignalOSCore-Swift.h>

@interface OneSignalPlugin ()

@property(strong, nonatomic) FlutterMethodChannel *channel;

@end

// Fork: persisted gate for the cached-appId auto-init below. Same key and store
// (OneSignalUserDefaults.initShared) as OSUD_AUTO_INIT_ALLOWED in the forked
// iOS SDK, so it also works against the upstream XCFramework. Unset = NO.
static NSString *const kOSAutoInitAllowedKey = @"onesignal_auto_init_allowed";

// Fork: the notification service extension runs the upstream
// OneSignalExtension binary, which sends receive receipts based on the shared
// flag the SDK stores from ios_params (App Group defaults, mirrored in
// OSResilientStorage for locked-device reads). While the gate is off OneSignal
// must stay silent, so turn receipts off there too. An explicit initialize
// fetches ios_params again and restores the server value.
static void OSFlutterDisableReceiveReceipts(void) {
  [OneSignalUserDefaults.initShared saveBoolForKey:OSUD_RECEIVE_RECEIPTS_ENABLED
                                         withValue:NO];
  [OSResilientStorage setString:@"0"
                         forKey:OSResilientStorage.keyReceiveReceiptsEnabled];
}

@implementation OneSignalPlugin

+ (instancetype)sharedInstance {
  static OneSignalPlugin *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [OneSignalPlugin new];
  });
  return sharedInstance;
}

#pragma mark FlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {

  OneSignalWrapper.sdkType = @"flutter";
  OneSignalWrapper.sdkVersion = @"050700";
  // Fork: only self-init from the cached appId when the host app allowed it.
  if ([OneSignalUserDefaults.initShared getSavedBoolForKey:kOSAutoInitAllowedKey
                                              defaultValue:NO])
    [OneSignal initialize:nil withLaunchOptions:nil];
  else
    OSFlutterDisableReceiveReceipts();

  OneSignalPlugin.sharedInstance.channel =
      [FlutterMethodChannel methodChannelWithName:@"OneSignal"
                                  binaryMessenger:[registrar messenger]];

  [registrar addMethodCallDelegate:OneSignalPlugin.sharedInstance
                           channel:OneSignalPlugin.sharedInstance.channel];
  [OSFlutterDebug registerWithRegistrar:registrar];
  [OSFlutterUser registerWithRegistrar:registrar];
  [OSFlutterNotifications registerWithRegistrar:registrar];
  [OSFlutterSession registerWithRegistrar:registrar];
  [OSFlutterLocation registerWithRegistrar:registrar];
  [OSFlutterInAppMessages registerWithRegistrar:registrar];
  [OSFlutterLiveActivities registerWithRegistrar:registrar];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([@"OneSignal#initialize" isEqualToString:call.method])
    [self initialize:call withResult:result];
  else if ([@"OneSignal#login" isEqualToString:call.method])
    [self login:call withResult:result];
  else if ([@"OneSignal#logout" isEqualToString:call.method])
    [self logout:call withResult:result];
  else if ([@"OneSignal#consentRequired" isEqualToString:call.method])
    [self setConsentRequired:call withResult:result];
  else if ([@"OneSignal#consentGiven" isEqualToString:call.method])
    [self setConsentGiven:call withResult:result];
  else if ([@"OneSignal#setAutoInitAllowed" isEqualToString:call.method])
    [self setAutoInitAllowed:call withResult:result];
  else
    result(FlutterMethodNotImplemented);
}

#pragma mark Init

- (void)initialize:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  [OneSignalUserDefaults.initShared saveBoolForKey:kOSAutoInitAllowedKey
                                         withValue:YES];
  [OneSignal initialize:call.arguments[@"appId"] withLaunchOptions:nil];
  result(nil);
}

- (void)setAutoInitAllowed:(FlutterMethodCall *)call
                withResult:(FlutterResult)result {
  BOOL allowed = [call.arguments[@"allowed"] boolValue];
  [OneSignalUserDefaults.initShared saveBoolForKey:kOSAutoInitAllowedKey
                                         withValue:allowed];
  if (!allowed)
    OSFlutterDisableReceiveReceipts();
  result(nil);
}

#pragma mark Login Logout

- (void)login:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  [OneSignal login:call.arguments[@"externalId"]];
  result(nil);
}

- (void)logout:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  [OneSignal logout];
  result(nil);
}

#pragma mark Privacy Consent

- (void)setConsentGiven:(FlutterMethodCall *)call
             withResult:(FlutterResult)result {
  BOOL granted = [call.arguments[@"granted"] boolValue];
  [OneSignal setConsentGiven:granted];
  result(nil);
}

- (void)setConsentRequired:(FlutterMethodCall *)call
                withResult:(FlutterResult)result {
  BOOL required = [call.arguments[@"required"] boolValue];
  [OneSignal setConsentRequired:required];
  result(nil);
}

@end
