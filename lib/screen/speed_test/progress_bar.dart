import 'package:gamers_shield_vpn/screen/speed_test/palatte.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';

class ProgressBar {
  LinearPercentIndicator showBar(double displayPer) {
    return LinearPercentIndicator(
      width: 300,
      lineHeight: 24.0,
      percent: displayPer / 100.0,
      center: Text(
        "${displayPer.toStringAsFixed(1)}%",
        style: TextStyle(
          fontSize: 14.0,
          color: txtCol,
        ),
      ),
      barRadius: const Radius.circular(12.0),
      backgroundColor: progressBg,
      progressColor: progressFill,
    );
  }
}
