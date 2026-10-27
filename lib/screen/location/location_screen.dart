import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamers_shield_vpn/screen/drawer/animated_drawer.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/ads_service.dart';
import '../../controller/server_controller.dart';
import '../../utils/app_colors.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  bool searchSubmit = false;

  // Function to save server data to SharedPreferences
  Future<void> saveServerData(dynamic serverName, dynamic config, {bool autoConnect = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverName', serverName?.toString() ?? '');
    await prefs.setString('config', config?.toString() ?? '');
    if (autoConnect) {
      await prefs.setBool('autoConnect', true);
    }
  }

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void initState() {
    _loadBannerAd();
    super.initState();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    if (_isBannerAdReady) {
      _bannerAd.dispose();
    }
    super.dispose();
  }

  Widget _buildPingBadge(int? ping, bool isPinging) {
    if (isPinging) {
      return SizedBox(
        width: 14.h,
        height: 14.h,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.orange,
        ),
      );
    }
    if (ping == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "-- ms",
          style: GoogleFonts.roboto(
            color: Colors.white54,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (ping < 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Timeout",
          style: GoogleFonts.roboto(
            color: Colors.redAccent,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    Color color = ping < 150
        ? Colors.greenAccent
        : (ping < 300 ? Colors.amberAccent : Colors.orangeAccent);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            "$ping ms",
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerItem(
    BuildContext context,
    ServerController serverController,
    dynamic server,
  ) {
    String id = server['id'] ?? server['serverName'] ?? '';
    String config = server['config'] ?? '';
    int? ping = serverController.pingMap[id];
    bool isThisPinging = serverController.isPinging.value && ping == null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () async {
          await saveServerData(
            server["serverName"],
            server["config"],
          );
          Get.offAll(() => AnimatedDrawerScreen());
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (server['imagePath'] != null &&
                          server['imagePath'].toString().contains(','))
                        ClipOval(
                          child: Image.memory(
                            Uint8List.fromList(
                              const Base64Decoder().convert(
                                server['imagePath']!.split(',').last,
                              ),
                            ),
                            height: 35.h,
                            width: 35.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        ClipOval(
                          child: Icon(
                            Icons.language_rounded,
                            color: Colors.white70,
                            size: 32.h,
                          ),
                        ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          "${server["serverName"] ?? 'Server'}",
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (config.isNotEmpty && id.isNotEmpty) {
                          serverController.pingServer(id, config);
                        }
                      },
                      child: _buildPingBadge(ping, isThisPinging),
                    ),
                    SizedBox(width: 8.w),
                    Image.asset(
                      "assets/images/network.png",
                      height: 24.h,
                      width: 24.w,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServerController>(
      builder: (serverController) {
        return Scaffold(
          backgroundColor: AppColors.appBgColor,
          appBar: AppBar(
            backgroundColor: AppColors.appBgColor,
            elevation: 1,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: Text(
              "VPN Locations",
              style: GoogleFonts.inika(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
            actions: [
              // Manual Refresh Button
              IconButton(
                tooltip: "Update Server List",
                onPressed: serverController.isLoading
                    ? null
                    : () {
                        serverController.fetchServers(showToastOnResult: true);
                      },
                icon: serverController.isLoading
                    ? SizedBox(
                        width: 18.h,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
              ),

              // Ping All Button
              IconButton(
                tooltip: "Ping All Servers",
                onPressed: serverController.isPinging.value
                    ? null
                    : () {
                        Fluttertoast.showToast(msg: "Pinging all servers...");
                        serverController.pingAllServers();
                      },
                icon: serverController.isPinging.value
                    ? SizedBox(
                        width: 18.h,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      )
                    : const Icon(Icons.network_check_rounded, color: Colors.white),
              ),
            ],
          ),
          resizeToAvoidBottomInset: false,
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/map.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  if (_isBannerAdReady)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: _bannerAd.size.width.toDouble(),
                        height: _bannerAd.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd),
                      ),
                    ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        searchSubmit = value.isNotEmpty;
                      });
                      serverController.searchServers(value);
                    },
                    style: GoogleFonts.roboto(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(left: 12.r),
                      prefixIcon: Icon(Icons.search, size: 18.h, color: Colors.white70),
                      hintText: "Search location...",
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                  ),

                  // Connect to Fastest Server Button
                  GestureDetector(
                    onTap: () async {
                      if (serverController.serverData.isEmpty) {
                        Fluttertoast.showToast(msg: "No servers available");
                        return;
                      }

                      // If no pings yet, ping all first
                      if (serverController.pingMap.isEmpty) {
                        Fluttertoast.showToast(msg: "Testing latency to find fastest server...");
                        await serverController.pingAllServers();
                      }

                      var best = serverController.getBestServer();
                      if (best != null) {
                        int? delay = serverController.pingMap[best['id'] ?? best['serverName']];
                        Fluttertoast.showToast(
                          msg: "Connecting to fastest: ${best['serverName']} (${delay ?? 0} ms)",
                        );
                        await saveServerData(best['serverName'], best['config'], autoConnect: true);
                        Get.offAll(() => AnimatedDrawerScreen());
                      } else {
                        // If all timed out or no ping, connect to first
                        var first = serverController.serverData.first;
                        Fluttertoast.showToast(msg: "Connecting to ${first['serverName']}...");
                        await saveServerData(first['serverName'], first['config'], autoConnect: true);
                        Get.offAll(() => AnimatedDrawerScreen());
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffF57D1F), Color(0xffE25C08)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffF57D1F).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, color: Colors.white, size: 26.h),
                              SizedBox(width: 8.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Connect to Fastest Server",
                                    style: GoogleFonts.roboto(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Auto-detects lowest ping",
                                    style: GoogleFonts.roboto(
                                      color: Colors.white70,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16.h),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Server List with Pull-to-Refresh
                  Expanded(
                    child: (searchSubmit
                                ? serverController.filteredServerData
                                : serverController.serverData)
                            .isEmpty
                        ? Center(
                            child: serverController.isLoading
                                ? const CircularProgressIndicator(color: Colors.orange)
                                : Text(
                                    "No servers found",
                                    style: GoogleFonts.roboto(color: Colors.white70),
                                  ),
                          )
                        : RefreshIndicator(
                            color: Colors.orange,
                            backgroundColor: AppColors.appBgColor,
                            onRefresh: () async {
                              await serverController.fetchServers(showToastOnResult: true);
                            },
                            child: ListView.builder(
                              itemCount: searchSubmit
                                  ? serverController.filteredServerData.length
                                  : serverController.serverData.length,
                              padding: EdgeInsets.only(bottom: 20.h),
                              itemBuilder: (context, index) {
                                var list = searchSubmit
                                    ? serverController.filteredServerData
                                    : serverController.serverData;
                                return _buildServerItem(
                                  context,
                                  serverController,
                                  list[index],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
