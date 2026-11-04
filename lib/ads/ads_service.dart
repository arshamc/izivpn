import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdConfig {
  static bool isTestMode = true; // Safe developer test mode by default

  // Official Google AdMob Test Ad Unit IDs
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const String testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  // Production Placeholders (configured remotely from dashboard/CDN config)
  static String prodAndroidInterstitial = '';
  static String prodAndroidRewarded = '';
  static String prodIosInterstitial = '';
  static String prodIosRewarded = '';

  // Remote Dynamic Anti-Ban & Timeouts Policies
  static bool adsEnabled = true;
  static int tunnelTimeoutSec = 10; // Exactly 10-second tunnel connection timeout
  static int adLoadTimeoutSec = 20; // 20-second hard timeout for ad loading
  static int maxInterstitials24h = 2; // Strict frequency cap: max 2 per 24h
  static int cooldownMinutes = 180; // 3 hours cooldown
  static int vipDurationHours = 2; // 2-hour VIP unlock

  /// Scenario A vs Scenario B detector:
  /// True only when ads are enabled AND either isTestMode=true OR production IDs are present
  static bool get isAdReadyAndActive {
    if (!adsEnabled) return false;
    if (isTestMode) return true;
    return prodAndroidInterstitial.trim().isNotEmpty && prodAndroidRewarded.trim().isNotEmpty;
  }

  static void updateFromMap(Map<String, dynamic> data) {
    if (data.containsKey('ads_enabled')) adsEnabled = data['ads_enabled'] == true;
    if (data.containsKey('enabled')) adsEnabled = data['enabled'] == true;

    if (data.containsKey('is_test_mode')) isTestMode = data['is_test_mode'] == true;
    if (data.containsKey('isTestMode')) isTestMode = data['isTestMode'] == true;

    if (data.containsKey('tunnel_timeout_sec')) {
      tunnelTimeoutSec = (data['tunnel_timeout_sec'] as num).toInt();
    }
    if (data.containsKey('ad_load_timeout_sec')) {
      adLoadTimeoutSec = (data['ad_load_timeout_sec'] as num).toInt();
    } else if (data.containsKey('interstitialTimeoutSec')) {
      adLoadTimeoutSec = (data['interstitialTimeoutSec'] as num).toInt();
    }

    if (data.containsKey('max_daily_interstitials')) {
      maxInterstitials24h = (data['max_daily_interstitials'] as num).toInt();
    } else if (data.containsKey('interstitialCap24h')) {
      maxInterstitials24h = (data['interstitialCap24h'] as num).toInt();
    }

    if (data.containsKey('cooldown_hours')) {
      cooldownMinutes = ((data['cooldown_hours'] as num).toInt()) * 60;
    } else if (data.containsKey('interstitialCooldownMin')) {
      cooldownMinutes = (data['interstitialCooldownMin'] as num).toInt();
    }

    if (data.containsKey('rewardedVipDurationHours')) {
      vipDurationHours = (data['rewardedVipDurationHours'] as num).toInt();
    }

    final interId = (data['interstitial_id'] ?? data['prodAdUnitInterstitial'])?.toString();
    if (interId != null && interId.trim().isNotEmpty) {
      prodAndroidInterstitial = interId.trim();
    }

    final rewId = (data['rewarded_id'] ?? data['prodAdUnitRewarded'])?.toString();
    if (rewId != null && rewId.trim().isNotEmpty) {
      prodAndroidRewarded = rewId.trim();
    }
  }
}

class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal() {
    _loadBypassSettings();
  }

  bool isAppInForeground = true;
  bool justWatchedRewarded = false;
  bool bypassCooldowns = false;

  DateTime? _lastInterstitialShownTime;
  int _dailyInterstitialCount = 0;
  DateTime? _dailyCountResetDate;

  // Active ad reference for cleanup on lifecycle paused
  InterstitialAd? _activeInterstitialAd;
  RewardedAd? _activeRewardedAd;
  Timer? _activeTimeoutTimer;

  static const String _prefVipUntil = 'vip_unlock_until_millis';
  static const String _prefBypassCooldowns = 'dev_bypass_ad_cooldowns';

  Future<void> _loadBypassSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bypassCooldowns = prefs.getBool(_prefBypassCooldowns) ?? false;
  }

  Future<void> setBypassCooldowns(bool value) async {
    bypassCooldowns = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBypassCooldowns, value);
  }

  void setAppLifecycleState(AppLifecycleState state) {
    isAppInForeground = (state == AppLifecycleState.resumed);
    if (!isAppInForeground) {
      abortPendingAds();
    }
  }

  void abortPendingAds() {
    _activeTimeoutTimer?.cancel();
    _activeTimeoutTimer = null;
    try {
      _activeInterstitialAd?.dispose();
    } catch (_) {}
    _activeInterstitialAd = null;
    try {
      _activeRewardedAd?.dispose();
    } catch (_) {}
    _activeRewardedAd = null;
  }

  String get interstitialAdUnitId {
    if (AdConfig.isTestMode || AdConfig.prodAndroidInterstitial.isEmpty) {
      return Platform.isIOS ? AdConfig.testIosInterstitial : AdConfig.testAndroidInterstitial;
    }
    return Platform.isIOS ? AdConfig.prodIosInterstitial : AdConfig.prodAndroidInterstitial;
  }

  String get rewardedAdUnitId {
    if (AdConfig.isTestMode || AdConfig.prodAndroidRewarded.isEmpty) {
      return Platform.isIOS ? AdConfig.testIosRewarded : AdConfig.testAndroidRewarded;
    }
    return Platform.isIOS ? AdConfig.prodIosRewarded : AdConfig.prodAndroidRewarded;
  }

  // --- VIP Membership & Timers ---
  Future<bool> isVipActive() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_prefVipUntil);
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<Duration> getVipRemainingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_prefVipUntil);
    if (until == null) return Duration.zero;
    final diff = until - DateTime.now().millisecondsSinceEpoch;
    return diff > 0 ? Duration(milliseconds: diff) : Duration.zero;
  }

  Future<void> unlockVipPass({Duration? duration}) async {
    final prefs = await SharedPreferences.getInstance();
    final dur = duration ?? Duration(hours: AdConfig.vipDurationHours);
    final expiry = DateTime.now().add(dur).millisecondsSinceEpoch;
    await prefs.setInt(_prefVipUntil, expiry);
    justWatchedRewarded = true;
  }

  Future<void> resetVipPass() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefVipUntil);
    justWatchedRewarded = false;
    _dailyInterstitialCount = 0;
    _lastInterstitialShownTime = null;
  }

  // --- AdMob Anti-Ban & Frequency Capping ---
  Future<bool> canShowPostConnectionInterstitial() async {
    // SCENARIO A: If ads are disabled or IDs are empty in production -> ZERO wait!
    if (!AdConfig.isAdReadyAndActive) return false;
    if (bypassCooldowns) return true; // Developer test panel override
    if (!AdConfig.adsEnabled) return false;
    if (justWatchedRewarded) {
      justWatchedRewarded = false;
      return false; // Skip if VIP rewarded video was just watched
    }
    if (await isVipActive()) return false; // Active VIP pass -> 100% ad-free

    final now = DateTime.now();
    if (_dailyCountResetDate == null || now.difference(_dailyCountResetDate!).inHours >= 24) {
      _dailyInterstitialCount = 0;
      _dailyCountResetDate = now;
    }

    if (_dailyInterstitialCount >= AdConfig.maxInterstitials24h) {
      return false; // 24h frequency cap reached (max 2)
    }

    if (_lastInterstitialShownTime != null) {
      final elapsed = now.difference(_lastInterstitialShownTime!).inMinutes;
      if (elapsed < AdConfig.cooldownMinutes) {
        return false; // Within 3-hour cooldown window
      }
    }

    return true;
  }

  void recordInterstitialShown() {
    _lastInterstitialShownTime = DateTime.now();
    _dailyInterstitialCount++;
  }

  /// Random Jitter Delay (800ms - 2000ms) after tun0 connects before requesting ad
  Future<void> applyJitterDelay({int minMs = 800, int maxMs = 2000}) async {
    final rand = Random();
    final ms = minMs + rand.nextInt(maxMs - minMs + 1);
    await Future.delayed(Duration(milliseconds: ms));
  }

  // Post-Connection Interstitial with 5s Hard Timeout
  Future<void> showPostConnectionInterstitial({
    BuildContext? context,
    required VoidCallback onComplete,
  }) async {
    if (!await canShowPostConnectionInterstitial()) {
      onComplete();
      return;
    }

    bool completed = false;

    void finishOnce() {
      if (!completed) {
        completed = true;
        _activeTimeoutTimer?.cancel();
        _activeTimeoutTimer = null;
        onComplete();
      }
    }

    // Set dynamic hard timeout (Scenario B: 20 seconds default)
    _activeTimeoutTimer = Timer(Duration(seconds: AdConfig.adLoadTimeoutSec), () {
      finishOnce();
    });

    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            if (completed) {
              ad.dispose();
              return;
            }
            _activeTimeoutTimer?.cancel();
            _activeTimeoutTimer = null;
            _activeInterstitialAd = ad;

            // Policy compliance: never show if app was backgrounded
            if (!isAppInForeground) {
              ad.dispose();
              _activeInterstitialAd = null;
              finishOnce();
              return;
            }

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                recordInterstitialShown();
                ad.dispose();
                _activeInterstitialAd = null;
                finishOnce();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _activeInterstitialAd = null;
                finishOnce();
              },
            );

            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            finishOnce();
          },
        ),
      );
    } catch (e) {
      finishOnce();
    }
  }

  // Rewarded VIP Ad with 8s Hard Timeout
  Future<void> showRewardedVipAd({
    BuildContext? context,
    required Function(bool success, String message) onResult,
  }) async {
    bool earnedReward = false;
    bool completed = false;

    void finishOnce(bool success, String message) {
      if (!completed) {
        completed = true;
        _activeTimeoutTimer?.cancel();
        _activeTimeoutTimer = null;
        onResult(success, message);
      }
    }

    // Hard 8-second timeout for rewarded video load
    _activeTimeoutTimer = Timer(Duration(seconds: AdConfig.rewardedTimeoutSec), () {
      finishOnce(false, "Rewarded ad load timed out. Please try again.");
    });

    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (completed) {
              ad.dispose();
              return;
            }
            _activeTimeoutTimer?.cancel();
            _activeTimeoutTimer = null;
            _activeRewardedAd = ad;

            if (!isAppInForeground) {
              ad.dispose();
              _activeRewardedAd = null;
              finishOnce(false, "App was sent to background.");
              return;
            }

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) async {
                ad.dispose();
                _activeRewardedAd = null;
                if (earnedReward) {
                  await unlockVipPass(duration: Duration(hours: AdConfig.vipDurationHours));
                  finishOnce(true, "VIP Pass Activated for ${AdConfig.vipDurationHours} Hours!");
                } else {
                  finishOnce(false, "VIP connection cancelled — video ad was not completed.");
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) async {
                ad.dispose();
                _activeRewardedAd = null;
                finishOnce(false, "Failed to present rewarded video.");
              },
            );

            ad.show(
              onUserEarnedReward: (ad, reward) {
                earnedReward = true;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) async {
            finishOnce(false, "Video ad not available at this moment.");
          },
        ),
      );
    } catch (e) {
      finishOnce(false, "Error loading rewarded ad: $e");
    }
  }
}

// Compatibility bridge
class AdHelper {
  static String get interstitialAdUnitId => AdManager.instance.interstitialAdUnitId;
  static String get rewardedAdUnitId => AdManager.instance.rewardedAdUnitId;
}
