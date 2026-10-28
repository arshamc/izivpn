import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:share_extend/share_extend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../ads/ads_service.dart';
import '../../utils/app_colors.dart';
import '../../widget/frosted_card.dart';
import '../home/home_screen.dart';

final ZoomDrawerController zoomDrawerController = ZoomDrawerController();

class AnimatedDrawerScreen extends StatelessWidget {
  const AnimatedDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: ZoomDrawer(
        controller: zoomDrawerController,
        menuScreen: const SettingsDrawerContent(),
        mainScreen: const HomeScreen(),
        borderRadius: 24.0,
        showShadow: true,
        angle: 0.0,
        slideWidth: MediaQuery.of(context).size.width * 0.78,
        menuBackgroundColor: const Color(0xFF1E293B),
        shadowLayer1Color: AppColors.brandCoral.withOpacity(0.15),
        shadowLayer2Color: Colors.black.withOpacity(0.2),
      ),
    );
  }
}

class SettingsDrawerContent extends StatefulWidget {
  const SettingsDrawerContent({super.key});

  @override
  State<SettingsDrawerContent> createState() => _SettingsDrawerContentState();
}

class _SettingsDrawerContentState extends State<SettingsDrawerContent> {
  bool _killSwitch = true;
  bool _splitTunneling = false;
  bool _autoReconnect = true;
  bool _protocolVless = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _killSwitch = prefs.getBool('kill_switch') ?? true;
      _splitTunneling = prefs.getBool('split_tunneling') ?? false;
      _autoReconnect = prefs.getBool('auto_reconnect_setting') ?? true;
      _protocolVless = prefs.getBool('protocol_vless') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FrostedCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      borderRadius: 18.r,
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.headingText(context), size: 18),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.headingText(context),
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: AppColors.brandCoral,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF64748B),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background misty artwork
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_inner_screens_mist.jpg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Badge & Version
                  Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: AppColors.brandCoral.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandCoral,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          color: AppColors.brandCoral,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'izi vpn',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.headingText(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'v1.2.0',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.subtitleText(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Core VPN Toggles
                  _buildToggleTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Kill Switch',
                    value: _killSwitch,
                    onChanged: (v) {
                      setState(() => _killSwitch = v);
                      _saveSetting('kill_switch', v);
                    },
                  ),
                  SizedBox(height: 10.h),

                  _buildToggleTile(
                    icon: Icons.alt_route_rounded,
                    title: 'Split Tunneling',
                    value: _splitTunneling,
                    onChanged: (v) {
                      setState(() => _splitTunneling = v);
                      _saveSetting('split_tunneling', v);
                    },
                  ),
                  SizedBox(height: 10.h),

                  _buildToggleTile(
                    icon: Icons.sync_rounded,
                    title: 'Auto Reconnect',
                    value: _autoReconnect,
                    onChanged: (v) {
                      setState(() => _autoReconnect = v);
                      _saveSetting('auto_reconnect_setting', v);
                    },
                  ),
                  SizedBox(height: 10.h),

                  _buildToggleTile(
                    icon: Icons.hub_outlined,
                    title: 'Protocol VLESS',
                    value: _protocolVless,
                    onChanged: (v) {
                      setState(() => _protocolVless = v);
                      _saveSetting('protocol_vless', v);
                    },
                  ),
                  SizedBox(height: 10.h),

                  // VIP Pass & AdMob Status Card
                  FrostedCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    borderRadius: 18.r,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: const Color(0xFFFFB74D),
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'VIP & Ad Controls',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingText(context),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AdConfig.isTestMode
                                    ? const Color(0xFFE0F2FE)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                AdConfig.isTestMode ? 'Test IDs' : 'Production',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AdConfig.isTestMode
                                      ? const Color(0xFF0369A1)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Google AdMob test IDs are active to safeguard against developer IVT account suspensions.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.subtitleText(context),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: () async {
                            await AdManager.instance.resetVipPass();
                            Fluttertoast.showToast(msg: "VIP pass and ad cooldowns reset");
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '🔄 Reset VIP & Ad Timers',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingText(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Google Play Compliance Grouped Card
                  FrostedCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    borderRadius: 20.r,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: AppColors.headingText(context),
                            size: 20,
                          ),
                          title: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingText(context),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          onTap: () async {
                            final uri = Uri.parse('https://policies.google.com/privacy');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
                        ),
                        Divider(color: Colors.black.withOpacity(0.06), height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.star_outline_rounded,
                            color: AppColors.headingText(context),
                            size: 20,
                          ),
                          title: Text(
                            'Rate Us',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingText(context),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          onTap: () async {
                            final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.arshadevelop.izivpn');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
                        ),
                        Divider(color: Colors.black.withOpacity(0.06), height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.share_outlined,
                            color: AppColors.headingText(context),
                            size: 20,
                          ),
                          title: Text(
                            'Share App',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingText(context),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          onTap: () {
                            ShareExtend.share(
                              'Download izi vpn - Fast & Secure: https://play.google.com/store/apps/details?id=com.arshadevelop.izivpn',
                              'text',
                            );
                          },
                        ),
                        Divider(color: Colors.black.withOpacity(0.06), height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.send_rounded,
                            color: AppColors.brandCoral,
                            size: 20,
                          ),
                          title: Text(
                            'Telegram Support',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingText(context),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          onTap: () async {
                            final uri = Uri.parse('https://t.me/izivpn_support');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
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
    );
  }
}
