import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/ads_service.dart';
import '../../controller/server_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/circular_flag.dart';
import '../../widget/frosted_card.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String? _selectedServerId;
  bool _isVipActive = false;
  Duration _vipRemaining = Duration.zero;
  Timer? _vipTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
    _checkVipState();
    _vipTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkVipState());
  }

  Future<void> _checkVipState() async {
    final active = await AdManager.instance.isVipActive();
    final rem = await AdManager.instance.getVipRemainingDuration();
    if (mounted) {
      setState(() {
        _isVipActive = active;
        _vipRemaining = rem;
      });
    }
  }

  Future<void> _loadCurrentServer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedServerId = prefs.getString('serverId');
    });
  }

  Future<void> _selectServer(Map<String, dynamic> server, {bool autoConnect = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final config = ServerController.sanitizeConfig(server['config']?.toString() ?? '');
    await prefs.setString('serverId', server['id']?.toString() ?? '');
    await prefs.setString('serverName', server['serverName']?.toString() ?? 'United States');
    await prefs.setString('country', server['country']?.toString() ?? 'United States');
    await prefs.setString('flag', server['flag']?.toString() ?? 'us');
    await prefs.setString('config', config);
    if (autoConnect) {
      await prefs.setBool('autoConnect', true);
    }
    Get.back();
  }

  void _onServerCardTapped(Map<String, dynamic> server) async {
    final isVip = server['vip'] == true || server['isVip'] == true;
    if (isVip && !_isVipActive) {
      _showVipUnlockBottomSheet(context, server);
    } else {
      await _selectServer(server, autoConnect: true);
    }
  }

  void _showVipUnlockBottomSheet(BuildContext context, Map<String, dynamic> server) {
    bool isLoadingAd = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2430),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Little Pill drag handle
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Crown VIP Icon
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7043).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Text(
                    'Unlock High-Speed VIP Server',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    'Watch a short sponsor video to unlock 2 Hours of unlimited high-speed access to all VIP locations with zero ads.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),

                  // Watch Video Button
                  GestureDetector(
                    onTap: isLoadingAd
                        ? null
                        : () async {
                            setModalState(() => isLoadingAd = true);
                            await AdManager.instance.showRewardedVipAd(
                              onResult: (success, message) async {
                                if (mounted && Navigator.canPop(bottomSheetContext)) {
                                  Navigator.pop(bottomSheetContext);
                                }
                                Fluttertoast.showToast(msg: message);
                                if (success) {
                                  await _checkVipState();
                                  await _selectServer(server, autoConnect: true);
                                }
                              },
                            );
                          },
                    child: Container(
                      width: double.infinity,
                      height: 52.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandCoral, Color(0xFFFF7A6A)],
                        ),
                        borderRadius: BorderRadius.circular(26.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandCoral.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isLoadingAd
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '🎬 Watch Video & Unlock (2h VIP)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _vipTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildPingBadge(int? ping, bool isPinging) {
    if (ping == null && isPinging) {
      return SizedBox(
        width: 14.w,
        height: 14.w,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.brandCoral,
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String text;

    if (ping == null || ping == 0) {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
      text = "• -- ms";
    } else if (ping < 0) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = AppColors.statusRed;
      text = "• Timeout";
    } else if (ping < 120) {
      bgColor = const Color(0xFFE6F9F0);
      textColor = AppColors.statusGreen;
      text = "• $ping ms";
    } else if (ping <= 280) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = AppColors.statusAmber;
      text = "• $ping ms";
    } else {
      bgColor = const Color(0xFFFEE2E2);
      textColor = AppColors.statusRed;
      text = "• $ping ms";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _detectProtocol(String config) {
    if (config.startsWith('trojan://')) return 'TROJAN';
    if (config.startsWith('ss://')) return 'SHADOWSOCKS';
    return 'VLESS';
  }

  @override
  Widget build(BuildContext context) {
    final serverController = Get.find<ServerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background: Misty atmospheric artwork for inner screens
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_inner_screens_mist.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient overlay for dark mode adaptation
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.obsidianBlack.withOpacity(0.55),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Header
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(
                              serverController.lastSyncTime.value.isNotEmpty
                                  ? '● Synced ${serverController.lastSyncTime.value} (${serverController.serverData.length} Servers)'
                                  : 'izi vpn servers (${serverController.serverData.length})',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            )),
                            Text(
                              'Select Location',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VIP Active Badge or Ping All
                      if (_isVipActive)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7043).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                _formatRemaining(_vipRemaining),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isVipActive) SizedBox(width: 8.w),

                      // "Ping All" Coral Button
                      Obx(() {
                        final isPinging = serverController.isPinging.value;
                        return GestureDetector(
                          onTap: () {
                            if (!isPinging) {
                              serverController.pingAllServers();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandCoral,
                              borderRadius: BorderRadius.circular(22.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandCoral.withOpacity(0.45),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPinging) ...[
                                  SizedBox(
                                    width: 12.w,
                                    height: 12.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                ],
                                Text(
                                  isPinging ? 'Pinging...' : 'Ping All',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 2. Search Pill Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: Container(
                    height: 48.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.25),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 22,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: (v) => serverController.searchServers(v),
                            style: const TextStyle(color: Colors.white),
                            cursorColor: AppColors.brandCoral,
                            decoration: InputDecoration(
                              hintText: 'Search country or protocol...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Smart Hero Card: "⚡ Connect to Fastest Server"
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                  child: GestureDetector(
                    onTap: () async {
                      var best = serverController.getBestServer();
                      if (best == null && serverController.serverData.isNotEmpty) {
                        best = Map<String, dynamic>.from(serverController.serverData.first);
                      }
                      if (best != null) {
                        Fluttertoast.showToast(
                          msg: "Connecting to fastest server: ${best['serverName']}",
                        );
                        _onServerCardTapped(best);
                      }
                    },
                    child: Container(
                      height: 56.h,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.brandCoral,
                            size: 24.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Connect to Fastest Server',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 14.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Server List
                Expanded(
                  child: GetBuilder<ServerController>(
                    builder: (controller) {
                      if (controller.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandCoral,
                          ),
                        );
                      }

                      final servers = controller.filteredServerData;
                      return RefreshIndicator(
                        color: AppColors.brandCoral,
                        onRefresh: () async {
                          await controller.fetchServers(showToastOnResult: true);
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                          itemCount: servers.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final server = servers[index] as Map<String, dynamic>;
                            final id = (server['id'] ?? server['serverName'] ?? '').toString();
                            final name = (server['serverName'] ?? 'Unknown Server').toString();
                            final flag = (server['flag'] ?? 'global').toString();
                            final config = (server['config'] ?? '').toString();
                            final protocol = _detectProtocol(config);
                            final isVip = server['vip'] == true || server['isVip'] == true;
                            final ping = controller.pingMap[id];
                            final isPinging = controller.isPinging.value;
                            final isSelected = id == _selectedServerId;

                            return FrostedCard(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              borderRadius: 20.r,
                              onTap: () => _onServerCardTapped(server),
                              child: Row(
                                children: [
                                  // Circular Vector Flag
                                  CircularFlagWidget(
                                    flagCode: flag,
                                    size: 34.w,
                                    isSelected: isSelected,
                                  ),
                                  SizedBox(width: 14.w),

                                  // Country / Server Name & Protocol
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.headingText(context),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isVip) ...[
                                              SizedBox(width: 6.w),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.workspace_premium_rounded,
                                                      color: Colors.white,
                                                      size: 11.sp,
                                                    ),
                                                    SizedBox(width: 2.w),
                                                    Text(
                                                      'VIP',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.sp,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 7.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6.r),
                                          ),
                                          child: Text(
                                            protocol,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Ping Badge
                                  _buildPingBadge(ping, isPinging),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
