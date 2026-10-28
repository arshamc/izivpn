import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }

  Future<void> _loadCurrentServer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedServerId = prefs.getString('serverId');
    });
  }

  Future<void> _selectServer(Map<String, dynamic> server, {bool autoConnect = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverId', server['id']?.toString() ?? '');
    await prefs.setString('serverName', server['serverName']?.toString() ?? 'United States');
    await prefs.setString('country', server['country']?.toString() ?? 'United States');
    await prefs.setString('flag', server['flag']?.toString() ?? 'us');
    await prefs.setString('config', server['config']?.toString() ?? '');
    if (autoConnect) {
      await prefs.setBool('autoConnect', true);
    }
    Get.back();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildPingBadge(int? ping, bool isPinging) {
    if (isPinging) {
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
                            Text(
                              'izi vpn',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
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
                        await _selectServer(best, autoConnect: true);
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
                            final id = server['id'] ?? server['serverName'] ?? '';
                            final name = server['serverName'] ?? 'Unknown Server';
                            final flag = server['flag'] ?? 'un';
                            final config = server['config'] ?? '';
                            final protocol = _detectProtocol(config);
                            final ping = controller.pingMap[id];
                            final isPinging = controller.isPinging.value;
                            final isSelected = id == _selectedServerId;

                            return FrostedCard(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              borderRadius: 20.r,
                              onTap: () => _selectServer(server, autoConnect: true),
                              child: Row(
                                children: [
                                  // Circular Vector Flag in Tactile Ring
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
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.headingText(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
