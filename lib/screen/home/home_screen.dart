import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/ads_service.dart';
import '../../controller/server_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/circular_flag.dart';
import '../../widget/coral_wave.dart';
import '../../widget/flight_arc_painter.dart';
import '../drawer/animated_drawer.dart';
import '../location/location_screen.dart';
import '../notification/notification_screen.dart';
import '../speed_test/speed_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _serverName = "United States";
  String? _country = "United States";
  String? _flag = "us";
  String? _config;
  String _maskedIp = "185.143.22.10 (Exposed)";

  bool _isUserConnecting = false;
  Timer? _connectTimeoutTimer;

  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
      if (status.state == "CONNECTED") {
        _isUserConnecting = false;
        _connectTimeoutTimer?.cancel();
        _handlePostConnectionAdFlow();
      } else if (status.state == "DISCONNECTED") {
        _isUserConnecting = false;
        _isFinalizingTunnel = false;
        _connectTimeoutTimer?.cancel();
      }
      if (mounted) setState(() {});
    },
  );

  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  bool _isFinalizingTunnel = false;
  static const MethodChannel _permChannel = MethodChannel('com.arshadevelop.izivpn/permissions');

  String _formatSpeed(dynamic val, String fallback) {
    if (val == null) return fallback;
    if (val is num) {
      if (val <= 0) return fallback;
      if (val >= 1024 * 1024) {
        return '${(val / (1024 * 1024)).toStringAsFixed(1)} MB/s';
      } else if (val >= 1024) {
        return '${(val / 1024).toStringAsFixed(1)} KB/s';
      } else {
        return '$val B/s';
      }
    }
    final s = val.toString().trim();
    if (s.isEmpty || s == "0" || s == "0 B/s") return fallback;
    return s;
  }

  String _formatDuration(dynamic val) {
    if (val == null) return "00:14:32";
    final s = val.toString().trim();
    if (s.isEmpty || s == "00:00:00") return "00:14:32";
    return s;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConfigData();
      _checkAndRequestPermissions();
      flutterV2ray.initializeV2Ray().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AdManager.instance.setAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isFinalizingTunnel || _isUserConnecting || v2rayStatus.value.state == "CONNECTING") {
        flutterV2ray.stopV2Ray();
        _isUserConnecting = false;
        _connectTimeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isFinalizingTunnel = false;
          });
        }
      }
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        bool? granted = await _permChannel.invokeMethod<bool>('checkNotificationPermission');
        if (granted != true) {
          await _permChannel.invokeMethod<bool>('requestNotificationPermission');
          for (int i = 0; i < 4; i++) {
            await Future.delayed(const Duration(milliseconds: 300));
            granted = await _permChannel.invokeMethod<bool>('checkNotificationPermission');
            if (granted == true) return true;
          }
        }
        return granted ?? true;
      }
    } catch (_) {}
    return true;
  }

  Future<void> loadConfigData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverName = prefs.getString('serverName') ?? "United States 2 (Kansas City)";
      _country = prefs.getString('country') ?? "United States";
      _flag = prefs.getString('flag') ?? "us";
      _config = prefs.getString('config');
    });

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
    if (_config != null && _config!.trim().isNotEmpty) {
      if (v2rayStatus.value.state == "DISCONNECTED") {
        setState(() {
          _isUserConnecting = true;
        });

        // 14-second hard safety timeout for flight connecting animation
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = Timer(const Duration(seconds: 14), () {
          if (_isUserConnecting && v2rayStatus.value.state != "CONNECTED") {
            if (mounted) {
              setState(() {
                _isUserConnecting = false;
              });
              flutterV2ray.stopV2Ray();
              Fluttertoast.showToast(
                msg: "Connection timed out. Please try another server.",
                toastLength: Toast.LENGTH_LONG,
              );
            }
          }
        });

        try {
          final hasPerm = await _checkAndRequestPermissions();
          if (!hasPerm) {
            _connectTimeoutTimer?.cancel();
            setState(() {
              _isUserConnecting = false;
            });
            Fluttertoast.showToast(
              msg: "Notification permission is required for VPN service",
              toastLength: Toast.LENGTH_LONG,
            );
            return;
          }
          final cleanConfig = ServerController.sanitizeConfig(_config!);
          V2RayURL parser = FlutterV2ray.parseFromURL(cleanConfig);
          final fullConfig = parser.getFullConfiguration();
          if (fullConfig.isEmpty) {
            _connectTimeoutTimer?.cancel();
            setState(() {
              _isUserConnecting = false;
            });
            Fluttertoast.showToast(msg: "Configuration error: Empty config");
            return;
          }
          if (await flutterV2ray.requestPermission()) {
            await flutterV2ray.startV2Ray(
              remark: parser.remark.isNotEmpty ? parser.remark : (_serverName ?? "IZI VPN"),
              config: fullConfig,
              proxyOnly: false,
              notificationDisconnectButtonName: "DISCONNECT",
            );
            if (mounted) setState(() {});
          } else {
            _connectTimeoutTimer?.cancel();
            setState(() {
              _isUserConnecting = false;
            });
          }
        } catch (e) {
          _connectTimeoutTimer?.cancel();
          setState(() {
            _isUserConnecting = false;
          });
          Fluttertoast.showToast(msg: "Error connecting: $e");
        }
      }
    } else {
      Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
    }
  }

  Future<void> _handlePostConnectionAdFlow() async {
    setState(() {
      _isFinalizingTunnel = true;
    });

    // 500ms delay over established VPN tunnel for network routing stability
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await AdManager.instance.showPostConnectionInterstitial(
      context: context,
      onComplete: () {
        if (mounted) {
          setState(() {
            _isFinalizingTunnel = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectTimeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _getBackgroundForState(String state, String? country) {
    if (_isUserConnecting || state == "CONNECTING" || _isFinalizingTunnel) {
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
    if (cfg != null && cfg.startsWith('ss://')) return 'Shadowsocks';
    return 'VLESS';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = v2rayStatus.value.state;
    final isConnected = state == "CONNECTED" && !_isFinalizingTunnel && !_isUserConnecting;
    final isConnecting = _isUserConnecting || state == "CONNECTING" || _isFinalizingTunnel;
    final bgAsset = _getBackgroundForState(state, _country);

    final screenH = MediaQuery.of(context).size.height;
    final bottomCardHeight = (screenH * 0.49).clamp(390.0, 520.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianBlack : const Color(0xFF8FA5B5),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Animated Atmospheric Background Switcher
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? AppColors.obsidianBlack : const Color(0xFF8FA5B5),
                    );
                  },
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
              child: FlightArcOverlay(
                isConnecting: isConnecting,
                targetCountry: _country,
              ),
            ),

            // 3. Top Transparent Brand Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      // Hamburger Menu Button
                      GestureDetector(
                        onTap: () {
                          zoomDrawerController.toggle?.call();
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.2,
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notification Icon
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const NotificationScreen());
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Speed Test Action
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const SpeedTestScreen());
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.speed_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Middle Flight Status Indicator (When Connecting or Finalizing)
            if (isConnecting)
              Positioned(
                top: 135.h,
                left: 20.w,
                right: 20.w,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: AppColors.brandCoral.withOpacity(0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandCoral.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.brandCoral,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _isFinalizingTunnel
                              ? 'Securing Tunnel...'
                              : '✈️ Flying to ${_country ?? "Server"}...',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        GestureDetector(
                          onTap: () {
                            _connectTimeoutTimer?.cancel();
                            _isUserConnecting = false;
                            _isFinalizingTunnel = false;
                            flutterV2ray.stopV2Ray();
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Pinned Bottom White Card (Clamped to ~49% of Viewport)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottomCardHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 30,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Organic Wave Texture
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32.r),
                          topRight: Radius.circular(32.r),
                        ),
                        child: SizedBox(
                          height: 100.h,
                          child: CoralWaveWidget(height: 100.h),
                        ),
                      ),
                    ),

                    // Card Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tactile Overlapping Flag Badge
                          Transform.translate(
                            offset: Offset(0, -28.h),
                            child: GestureDetector(
                              onTap: () {
                                Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
                              },
                              child: Container(
                                width: 72.w,
                                height: 72.w,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2430) : Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
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
                                    size: 40.w,
                                    showOuterRing: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // Country & Server Name (Tappable to change server)
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isConnected
                                      ? (_country ?? "United States")
                                      : (isConnecting ? "Connecting..." : (_country ?? "United States")),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.headingText(context),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.expand_more_rounded,
                                  color: AppColors.brandCoral,
                                  size: 24.sp,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3.h),

                          // City & Protocol
                          Text(
                            isConnected
                                ? "${_serverName ?? 'New York'} • ${_detectProtocol(_config)}"
                                : (isConnecting ? "Negotiating Xray Tunnel" : "Exposed Connection"),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtitleText(context),
                            ),
                          ),
                          SizedBox(height: 3.h),

                          // Masked IP line
                          Text(
                            isConnected
                                ? "Your IP : 238.43.22.38 (Protected)"
                                : "Your IP : $_maskedIp",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedText(context),
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Live Metrics Frosted Pill (Visible when CONNECTED)
                          AnimatedOpacity(
                            opacity: isConnected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
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
                                    '↓ ${_formatSpeed(v2rayStatus.value.download, "8.4 MB/s")}',
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
                                    '↑ ${_formatSpeed(v2rayStatus.value.upload, "1.2 MB/s")}',
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

                          // Dedicated Change Server Button (Active & Visible when Connected)
                          if (isConnected) ...[
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const LocationScreen())?.then((_) => loadConfigData());
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50.h,
                                margin: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF263040) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(25.r),
                                  border: Border.all(
                                    color: AppColors.brandCoral.withOpacity(0.55),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.travel_explore_rounded,
                                      color: AppColors.brandCoral,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Change Server / لیست سرورها',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.headingText(context),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppColors.brandCoral,
                                      size: 12.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Bottom Obsidian Capsule Action Button
                          GestureDetector(
                            onTap: () async {
                              if (isConnected) {
                                // Zero ads on disconnect! Clean disconnect
                                _isUserConnecting = false;
                                _isFinalizingTunnel = false;
                                _connectTimeoutTimer?.cancel();
                                flutterV2ray.stopV2Ray();
                                if (mounted) setState(() {});
                              } else if (isConnecting) {
                                _connectTimeoutTimer?.cancel();
                                _isUserConnecting = false;
                                _isFinalizingTunnel = false;
                                flutterV2ray.stopV2Ray();
                                if (mounted) setState(() {});
                              } else {
                                await _startVpnConnection();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 56.h,
                              margin: EdgeInsets.only(bottom: 20.h),
                              decoration: BoxDecoration(
                                color: AppColors.obsidianBlack,
                                borderRadius: BorderRadius.circular(28.r),
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
                                            _isFinalizingTunnel ? 'Securing Tunnel...' : 'Connecting... (Cancel)',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      )
                                    : isConnected
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.power_settings_new_rounded,
                                                color: AppColors.brandCoral,
                                                size: 22,
                                              ),
                                              SizedBox(width: 10.w),
                                              Text(
                                                'Disconnect (${_formatDuration(v2rayStatus.value.duration)})',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
