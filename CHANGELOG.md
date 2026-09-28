## 5.7.0-noautoinit.3 (fork)

- Android: consume the forked native SDK 5.10.2-noautoinit.3 (explicit `initWithContext(appId)` persists the gate synchronously, so a later `setAutoInitAllowed(false)` always wins; gate writes use `commit()`).
- iOS: the optional forked native SDK is now `5.7.0-noautoinit.2`, built from source through CocoaPods (see README for the Podfile lines).

## 5.7.0-noautoinit.2 (fork)

- Android: consume the forked native SDK 5.10.2-noautoinit.2 (5.10.2-noautoinit.1 does not resolve on JitPack: its core depends on a fork `kmp` artifact that was never published).

## 5.7.0-noautoinit.1 (fork)

- Gate the native auto-init from the cached app id behind a persisted flag (`onesignal_auto_init_allowed`, default off). `initialize` turns it on.
- Add `OneSignal.setAutoInitAllowed(bool)`.
- Android: consume the forked native SDK 5.10.2-noautoinit.1 from JitPack.

Please see the release notes page for the full change log
https://github.com/OneSignal/OneSignal-Flutter-SDK/releases