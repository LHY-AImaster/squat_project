
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/squat_provider.dart';
import '../services/my_bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier {
  final MyBluetoothService _bluetoothService = MyBluetoothService();

  String _connectionStatus = 'DISCONNECTED';
  String get connectionStatus => _connectionStatus;

  /// Android 버전에 맞는 블루투스 권한 요청
  Future<bool> _requestBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12 이상
      final permissions = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      return permissions[Permission.bluetoothScan]?.isGranted == true &&
          permissions[Permission.bluetoothConnect]?.isGranted == true;
    } else {
      // Android 11 이하: BLE 스캔에 위치 권한 필요
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
  }

  /// 듀얼 아두이노 블루투스 연결 시작
  Future<void> startBluetoothWorkout(SquatProvider squatProvider) async {
    _connectionStatus = 'CONNECTING';
    notifyListeners();

    // 가상의 기기 검색 시간
    await Future.delayed(const Duration(seconds: 2));

    // 가상 연결 완료
    _connectionStatus = 'CONNECTED';
    notifyListeners();
  }

  /// 두 기기 연결 해제
  Future<void> disconnectArduino(
      SquatProvider squatProvider,
      ) async {
    try {
      await _bluetoothService.disconnectFromArduino();
    } finally {
      _connectionStatus = 'DISCONNECTED';
      squatProvider.stopReadingOnDisconnect();
      notifyListeners();
    }
  }
}
