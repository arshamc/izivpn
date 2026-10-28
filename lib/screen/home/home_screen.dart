import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/ads_service.dart';
import '../../controller/server_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/circular_flag.dart';
import '../../widget/coral_wave.dart';
import '../../widget/flight_arc_painter.dart';
import '../../widget/frosted_card.dart';
import '../drawer/animated_drawer.dart';
import '../location/location_screen.dart';
import '../notification/notification_screen.dart';
import '../speed_test/speed_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _serverName = "United States";
  String? _country = "United States";
  String? _flag = "us";
  String? _config;
  String _maskedIp = "185.143.22.10 (Exposed)";

  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
      if (mounted) setState(() {});
    },
  );

  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _createRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfigData();
      flutterV2ray.initializeV2Ray().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> loadConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverName = prefs.getString('serverName') ?? "United States 2 (Kansas City)";
      _country = prefs.getString('country') ?? "United States";
      _flag = prefs.getString('flag') ?? "us";
      _config = prefs.getString('config');
    });

    // Pick first default server if none selected
    if (_config == null || _config!.isEmpty) {
      final serverController = Get.find<ServerController>();
      if (serverController.serverData.isNotEmpty) {
        final first = serverController.serverData.first;
        setState(() {
          _serverName = first['serverName'] ?? "United States";
          _country = first['country'] ?? "United States";
          _flag = first['flag'] ?? "us";
          _config = first['config'];
        });
      }
    }

    if (prefs.getBool('autoConnect') == true) {
      await prefs.setBool('autoConnect', false);
      Future.delayed(const Duration(milliseconds: 350), () {
        _startVpnConnection();
      });
    }
  }

  Future<void> _startVpnConnection() async {
    if (_config != null && _config!.isNotEmpty) {
      if (v2rayStatus.value.state == "DISCONNECTED") {
        try {
          V2RayURL parser = FlutterV2ray.parseFromURL(_config!);
          if (await flutterV2ray.requestPermission()) {
            await flutterV2ray.startV2Ray(
              remark: parser.remark.isNotEmpty ? parser.remark : (_serverName ?? "IZI VPN"),
              config: parser.getFullConfiguration(),
              proxyOnly: false,
            );
            if (mounted) setState(() {});
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Error connecting: $e");
        }
      }
    } else {
      Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < 3) {
            _createRewardedAd();
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _createRewardedAd();
      },
    );
    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(onUserEarnedReward: (_, __) {});
    _rewardedAd = null;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  String _getBackgroundForState(String state, String? country) {
    if (state == "CONNECTING") {
      return 'assets/images/bg_connecting_flight.jpg';
    }
    if (state == "CONNECTED") {
      final c = (country ?? '').toLowerCase();
      if (c.contains('united states') || c.contains('usa') || c.contains('us')) {
        return 'assets/images/bg_usa.jpg';
      }
      if (c.contains('france') || c.contains('paris') || c.contains('fr')) {
        return 'assets/images/bg_france.jpg';
      }
      if (c.contains('united kingdom') || c.contains('uk') || c.contains('london') || c.contains('gb')) {
        return 'assets/images/bg_uk.jpg';
      }
      if (c.contains('germany') || c.contains('de')) {
        return 'assets/images/bg_germany.jpg';
      }
      if (c.contains('netherlands') || c.contains('amsterdam') || c.contains('nl')) {
        return 'assets/images/bg_netherlands.jpg';
      }
      if (c.contains('turkey') || c.contains('istanbul') || c.contains('tr')) {
        return 'assets/images/bg_turkey.jpg';
      }
      return 'assets/images/bg_germany.jpg';
    }
    return 'assets/images/bg_disconnected.jpg';
  }

  String _detectProtocol(String? cfg) {
    if (cfg != null && cfg.startsWith('trojan://')) return 'Trojan';
    return 'VLESS';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = v2rayStatus.value.state;
    final isConnected = state == "CONNECTED";
    final isConnecting = state == "CONNECTING";
    final bgAsset = _getBackgroundForState(state, _country);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Animated Atmospheric Background Switcher
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.04, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                bgAsset,
                key: ValueKey<String>(bgAsset),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Dark mode shader tint
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.obsidianBlack.withOpacity(0.55),
              ),
            ),

          // 2. Interactive Flight Arc Overlay (active during CONNECTING)
          Positioned.fill(
            child: FlightArcOverlay(isConnecting: isConnecting),
          ),

          // 3. Top Transparent Brand Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  // Hamburger Menu Button
                  GestureDetector(
                    onTap: () {
                      zoomDrawerController.toggle!();
                    },
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  // Center Brand Logo & Title
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 26.w,
                          height: 26.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandCoral,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'izi vpn',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Speed Test Quick Action
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => const SpeedTestScreen(),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Notification Bell with Coral Unread Dot
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => const NotificationScreen(),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.brandCoral,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Foreground Section with Coral Wave & White Fog
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CoralWaveWidget(
              height: 375.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Flag Badge (Tapping opens Location Screen)
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
                      },
                      child: Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: isConnected ? AppColors.brandCoral : const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isConnected
                                  ? AppColors.brandCoral.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CircularFlagWidget(
                            flagCode: _flag ?? 'us',
                            size: 42.w,
                            showOuterRing: false,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Country & Server Name
                    Text(
                      isConnected
                          ? (_country ?? "United States")
                          : (isConnecting ? "Connecting..." : "Unsecured Network"),
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.headingText(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // City & Protocol
                    Text(
                      isConnected
                          ? "${_serverName ?? 'New York'} • ${_detectProtocol(_config)}"
                          : (isConnecting ? "Negotiating Xray Tunnel" : "Exposed Connection"),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitleText(context),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Masked IP line
                    Text(
                      isConnected
                          ? "Your IP : 238.43.22.38"
                          : "Your IP : $_maskedIp",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Live Metrics Frosted Pill (Visible when CONNECTED)
                    AnimatedOpacity(
                      opacity: isConnected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '↓ ${v2rayStatus.value.download.isNotEmpty ? v2rayStatus.value.download : "8.4 MB/s"}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingText(context),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Text(
                              '↑ ${v2rayStatus.value.upload.isNotEmpty ? v2rayStatus.value.upload : "1.2 MB/s"}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingText(context),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.signal_cellular_alt_rounded,
                              color: AppColors.statusGreen,
                              size: 15.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '48 ms',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Bottom Obsidian Capsule Action Button
                    GestureDetector(
                      onTap: () async {
                        if (isConnected) {
                          _showRewardedAd();
                          flutterV2ray.stopV2Ray();
                        } else if (!isConnecting) {
                          await _startVpnConnection();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60.h,
                        margin: EdgeInsets.only(bottom: 24.h),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isConnecting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Connecting...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : isConnected
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 8.w,
                                          height: 8.w,
                                          decoration: const BoxDecoration(
                                            color: AppColors.statusGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Text(
                                          'Connected  ${v2rayStatus.value.duration.isNotEmpty ? v2rayStatus.value.duration : "00:14:32"}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.power_settings_new_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Tap to Connect',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
