import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamers_shield_vpn/screen/speed_test/palatte.dart';
import 'package:gamers_shield_vpn/screen/speed_test/progress_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';


import '../../ads/ads_service.dart';
import '../../utils/app_constant.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({Key? key}) : super(key: key);

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final internetSpeedTest = FlutterInternetSpeedTest()..enableLog();

  bool _testInProgress = false;
  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  int _downloadCompletionTime = 0;
  int _uploadCompletionTime = 0;
  bool _isServerSelectionInProgress = false;

  String? _ip;
  String? _asn;
  String? _isp;

  String _unitText = 'Mbps';

  // Value for NeedlePointer
  double _needlePointerValue = 0;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
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
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reset();
    });
  }

  void reset() {
    setState(() {
      {
        _testInProgress = false;
        _downloadRate = 0;
        _uploadRate = 0;
        _downloadProgress = '0';
        _uploadProgress = '0';
        _unitText = 'Mbps';
        _downloadCompletionTime = 0;
        _uploadCompletionTime = 0;

        _ip = null;
        _asn = null;
        _isp = null;
      }
    });
  }

  // Using a flag to prevent the user from interrupting running tests
  bool isTesting = false;

  final ProgressBar progressBar = ProgressBar();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 2,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: (){
            Get.back();
          },
          icon: Icon(Icons.arrow_back_ios,color: Colors.white,),
        ),
        title: Text('Internet Speed Test',style: GoogleFonts.inika(
            color: Colors.white,
            fontSize: 16.sp
        ),),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[

              SizedBox(height: 20.h,),
              if (_isBannerAdReady)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                ),
              SizedBox(height: 12.h,),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.arrow_downward, color: Colors.white,),
                            ),
                            SizedBox(height: 4,),
                            Text('Download',style: GoogleFonts.inika(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),),
                            SizedBox(height: 4,),
                            Text('$_downloadRate $_unitText', style: TextStyle(color: Colors.white,),),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.arrow_upward, color: Colors.white,),
                            ),
                            SizedBox(height: 4,),
                            Text('Upload',style: GoogleFonts.inika(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),),
                            SizedBox(height: 4,),
                            Text('$_uploadRate $_unitText', style: TextStyle(color: Colors.white,),),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfRadialGauge(
                  title: GaugeTitle(
                    text: '$_needlePointerValue $_unitText',
                    textStyle: const TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 150,
                      axisLabelStyle: GaugeTextStyle(
                      ),
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 50,
                          color: Colors.green,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                        GaugeRange(
                          startValue: 50,
                          endValue: 100,
                          color: Colors.orange,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                        GaugeRange(
                          startValue: 100,
                          endValue: 150,
                          color: Colors.red,
                          startWidth: 10,
                          endWidth: 10,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(
                          value: _needlePointerValue,
                          enableAnimation: true,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Container(
                            child: Text(
                              '$_needlePointerValue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.5,
                        )
                      ],
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _testInProgress ? null : 0,
                    strokeWidth: 6.0,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ),
              SizedBox(height: 25,),
              if(!_testInProgress)...{
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MaterialButton(
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: buttonGradient,
                          borderRadius: BorderRadius.all(Radius.circular(80.0)),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 188.0, minHeight: 46.0), // min sizes for Material buttons
                          alignment: Alignment.center,
                          child: const Text(
                            'Start Test',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0)),
                      padding: const EdgeInsets.all(0.0),
                      color: Colors.red,
                      textColor: txtCol,
                      onPressed: () async {
                        if (!_testInProgress) {
                          reset();
                          await internetSpeedTest.startTesting(
                            onStarted: () {
                              setState(() {
                                _testInProgress = true;
                              });
                            },
                            onCompleted: (TestResult download, TestResult upload) {
                              if (kDebugMode) {
                                print(
                                    'the transfer rate ${download.transferRate}, ${upload.transferRate}');
                              }
                              setState(() {
                                _downloadRate = download.transferRate;
                                _unitText =
                                download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                                _downloadProgress = '100';
                                _downloadCompletionTime = download.durationInMillis;
                                // Update NeedlePointer value
                                _needlePointerValue = _downloadRate;
                              });
                              setState(() {
                                _uploadRate = upload.transferRate;
                                _unitText =
                                upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                                _uploadProgress = '100';
                                _uploadCompletionTime = upload.durationInMillis;
                                // Update NeedlePointer value
                                _needlePointerValue = _uploadRate;
                                _testInProgress = false;
                              });
                            },
                            onProgress: (double percent, TestResult data) {
                              if (kDebugMode) {
                                print(
                                    'the transfer rate $data.transferRate, the percent $percent');
                              }
                              setState(() {
                                _unitText =
                                data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                                if (data.type == TestType.download) {
                                  _downloadRate = data.transferRate;
                                  _downloadProgress = percent.toStringAsFixed(2);
                                  // Update NeedlePointer value
                                  _needlePointerValue = _downloadRate;
                                } else {
                                  _uploadRate = data.transferRate;
                                  _uploadProgress = percent.toStringAsFixed(2);
                                  // Update NeedlePointer value
                                  _needlePointerValue = _uploadRate;
                                }
                              });
                            },
                            onError: (String errorMessage, String speedTestError) {
                              if (kDebugMode) {
                                print(
                                    'the errorMessage $errorMessage, the speedTestError $speedTestError');
                              }
                              reset();
                            },
                            onDefaultServerSelectionInProgress: () {
                              setState(() {
                                _isServerSelectionInProgress = true;
                              });
                            },
                            onDefaultServerSelectionDone: (Client? client) {
                              setState(() {
                                _isServerSelectionInProgress = false;
                                _ip = client?.ip;
                                _asn = client?.asn;
                                _isp = client?.isp;
                              });
                            },
                            onDownloadComplete: (TestResult data) {
                              setState(() {
                                _downloadRate = data.transferRate;
                                _unitText =
                                data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                                _downloadCompletionTime = data.durationInMillis;
                              });
                            },
                            onUploadComplete: (TestResult data) {
                              setState(() {
                                _uploadRate = data.transferRate;
                                _unitText =
                                data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                                _uploadCompletionTime = data.durationInMillis;
                              });
                            },
                            onCancel: () {
                              reset();
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              }
              else...{
                MaterialButton(
                  minWidth: 150,
                  height: 40,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(80.0)),
                  padding: const EdgeInsets.all(0.0),
                  color: Colors.red,
                  textColor: txtCol,
                  child: const Text('Cancel Test'),
                  onPressed: () => internetSpeedTest.cancelTest(),
                ),
              }
            ],
          ),
        ),
      ),
    );
  }
}
