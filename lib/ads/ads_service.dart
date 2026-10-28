import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdConfig {
  static bool isTestMode = true; // Safe testing by default to protect developer account

  // Official Google AdMob Test Ad Unit IDs
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';

  static const String testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  // Production Placeholders (configured remotely from dashboard)
  static String prodAndroidInterstitial = '';
  static String prodAndroidRewarded = '';
  static String prodIosInterstitial = '';
  static String prodIosRewarded = '';

  // Remote Anti-Ban Policies
  static bool adsEnabled = true;
  static int maxInterstitials24h = 2;
  static int cooldownMinutes = 180; // 3 hours cooldown
  static int interstitialTimeoutSec = 5;
  static int rewardedTimeoutSec = 8;
  static int vipDurationHours = 2;
  static int courtesyPassMin = 30;

  static void updateFromMap(Map<String, dynamic> data) {
    if (data.containsKey('enabled')) adsEnabled = data['enabled'] == true;
    if (data.containsKey('isTestMode')) isTestMode = data['isTestMode'] == true;
    if (data.containsKey('interstitialCap24h')) maxInterstitials24h = (data['interstitialCap24h'] as num).toInt();
    if (data.containsKey('interstitialCooldownMin')) cooldownMinutes = (data['interstitialCooldownMin'] as num).toInt();
    if (data.containsKey('interstitialTimeoutSec')) interstitialTimeoutSec = (data['interstitialTimeoutSec'] as num).toInt();
    if (data.containsKey('rewardedTimeoutSec')) rewardedTimeoutSec = (data['rewardedTimeoutSec'] as num).toInt();
    if (data.containsKey('rewardedVipDurationHours')) vipDurationHours = (data['rewardedVipDurationHours'] as num).toInt();
    if (data.containsKey('courtesyPassMin')) courtesyPassMin = (data['courtesyPassMin'] as num).toInt();

    final prodInter = data['prodAdUnitInterstitial']?.toString();
    if (prodInter != null && prodInter.trim().isNotEmpty) {
      prodAndroidInterstitial = prodInter.trim();
    }
    final prodRew = data['prodAdUnitRewarded']?.toString();
    if (prodRew != null && prodRew.trim().isNotEmpty) {
      prodAndroidRewarded = prodRew.trim();
    }
  }
}

class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();

  bool isAppInForeground = true;
  bool justWatchedRewarded = false;
  DateTime? _lastInterstitialShownTime;
  int _dailyInterstitialCount = 0;
  DateTime? _dailyCountResetDate;

  void setAppLifecycleState(AppLifecycleState state) {
    isAppInForeground = (state == AppLifecycleState.resumed);
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
  static const String _prefVipUntil = 'vip_unlock_until_millis';

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
    if (!AdConfig.adsEnabled) return false;
    if (justWatchedRewarded) {
      justWatchedRewarded = false;
      return false; // VIP rewarded video was just completed -> skip!
    }
    if (await isVipActive()) return false; // Active VIP pass -> 100% ad-free!

    final now = DateTime.now();
    if (_dailyCountResetDate == null || now.difference(_dailyCountResetDate!).inHours >= 24) {
      _dailyInterstitialCount = 0;
      _dailyCountResetDate = now;
    }

    if (_dailyInterstitialCount >= AdConfig.maxInterstitials24h) {
      return false; // 24h frequency cap reached
    }

    if (_lastInterstitialShownTime != null) {
      final elapsed = now.difference(_lastInterstitialShownTime!).inMinutes;
      if (elapsed < AdConfig.cooldownMinutes) {
        return false; // Still within cooldown window
      }
    }

    return true;
  }

  void recordInterstitialShown() {
    _lastInterstitialShownTime = DateTime.now();
    _dailyInterstitialCount++;
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
    Timer? timeoutTimer;

    void finishOnce() {
      if (!completed) {
        completed = true;
        timeoutTimer?.cancel();
        onComplete();
      }
    }

    // Set hard 5-second timeout
    timeoutTimer = Timer(Duration(seconds: AdConfig.interstitialTimeoutSec), () {
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
            timeoutTimer?.cancel();

            // Policy compliance: never show if app was backgrounded
            if (!isAppInForeground) {
              ad.dispose();
              finishOnce();
              return;
            }

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                recordInterstitialShown();
                ad.dispose();
                finishOnce();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
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

  // Rewarded VIP Ad with 8s Hard Timeout and Courtesy Pass Fallback
  Future<void> showRewardedVipAd({
    BuildContext? context,
    required Function(bool success, String message) onResult,
  }) async {
    bool earnedReward = false;
    bool completed = false;
    Timer? timeoutTimer;

    void finishOnce(bool success, String message) {
      if (!completed) {
        completed = true;
        timeoutTimer?.cancel();
        onResult(success, message);
      }
    }

    // 8s timeout fallback: grant 30-min courtesy pass
    timeoutTimer = Timer(Duration(seconds: AdConfig.rewardedTimeoutSec), () async {
      await unlockVipPass(duration: Duration(minutes: AdConfig.courtesyPassMin));
      finishOnce(true, "Courtesy VIP pass activated for ${AdConfig.courtesyPassMin} minutes!");
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
            timeoutTimer?.cancel();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) async {
                ad.dispose();
                if (earnedReward) {
                  await unlockVipPass(duration: Duration(hours: AdConfig.vipDurationHours));
                  finishOnce(true, "VIP Pass Activated for ${AdConfig.vipDurationHours} Hours!");
                } else {
                  finishOnce(false, "Video was closed before completion.");
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) async {
                ad.dispose();
                await unlockVipPass(duration: Duration(minutes: AdConfig.courtesyPassMin));
                finishOnce(true, "Courtesy VIP pass activated!");
              },
            );

            ad.show(
              onUserEarnedReward: (ad, reward) {
                earnedReward = true;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) async {
            await unlockVipPass(duration: Duration(minutes: AdConfig.courtesyPassMin));
            finishOnce(true, "Courtesy VIP pass activated!");
          },
        ),
      );
    } catch (e) {
      await unlockVipPass(duration: Duration(minutes: AdConfig.courtesyPassMin));
      finishOnce(true, "Courtesy VIP pass activated!");
    }
  }
}

// Compatibility bridge
class AdHelper {
  static String get interstitialAdUnitId => AdManager.instance.interstitialAdUnitId;
  static String get rewardedAdUnitId => AdManager.instance.rewardedAdUnitId;
  static String get bannerAdUnitId => AdConfig.testAndroidBanner;
}
