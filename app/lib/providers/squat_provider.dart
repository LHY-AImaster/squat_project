import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer_service.dart';
import '../utils/low_pass_filter.dart';
import '../models/squat_record.dart';
import '../services/database_helper.dart';

// 가상 스쿼트 시나리오
enum VirtualSquatScenario {
  normal,       // 정상
  waistError,   // 상체 과도하게 숙임
  shallow,      // 깊이 부족
  fast,         // 빠른 스쿼트
  combined,      // 복합 오류
}

class SquatProvider with ChangeNotifier {
  // 화면에 그릴 상태 데이터
  SquatData _data = SquatData(
    waistAngle: 0.0,
    thighAngle: 0.0,
  );

  SquatData get data => _data;

  // 로컬 운동 기록
  List<SquatRecord> _localRecords = [];
  List<SquatRecord> get localRecords => _localRecords;

  // 스쿼트 분석 서비스
  final SquatAnalyzerService _analyzer = SquatAnalyzerService();
  SquatAnalyzerService get analyzer => _analyzer;

  // 기준점(영점) 벡터
  List<double>? _baseWaistVec;
  List<double>? _baseThighVec;

  // 로우 패스 필터, alpha가 낮을수록 더 부드럽지만 반응이 느려짐
  final LowPassFilter _waistFilter = LowPassFilter(alpha: 0.15);
  final LowPassFilter _thighFilter = LowPassFilter(alpha: 0.15);

  // 데이터 수신 상태
  bool _isReading = false;
  bool get isReading => _isReading;

  // 가상 운동 타이머
  Timer? _virtualWorkoutTimer;
  Stopwatch? _virtualStopwatch;

  // 현재 진행 중인 가상 스쿼트 시나리오
  VirtualSquatScenario? _currentVirtualScenario;

  // 운동 시작
  void startReading() {
    if (_isReading) return;

    _isReading = true;

    _baseWaistVec = null;
    _baseThighVec = null;

    _waistFilter.reset();
    _thighFilter.reset();

    _analyzer.resetCurrentRepFlags();

    notifyListeners();
  }

  // 블루투스 연결 해제
  void stopReadingOnDisconnect() {
    // 가상 운동 타이머 정리
    _virtualWorkoutTimer?.cancel();
    _virtualWorkoutTimer = null;

    _virtualStopwatch?.stop();
    _virtualStopwatch = null;

    _isReading = false;
    _baseWaistVec = null;
    _baseThighVec = null;

    // 필터 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    // 진행 중이던 스쿼트 상태 초기화
    _analyzer.resetCurrentRepFlags();

    _updateState(
      waist: 0.0,
      thigh: 0.0,
      status: "⚠️ 블루투스 연결이 끊어졌습니다. 재연결을 기다리는 중...",
    );
  }

  // 블루투스 원본 데이터 처리
  void updateRawData(
      List<double> currentW,
      List<double> currentT,
      ) {
    if (!_isReading) return;

    // 영점 포착
    if (_baseWaistVec == null || _baseThighVec == null) {
      _baseWaistVec = currentW;
      _baseThighVec = currentT;

      _updateState(
        status: "영점 세팅 완료!",
      );

      return;
    }

    try {
      // 기준 벡터와 현재 벡터 사이의 상대 각도 계산
      double rawWAngle = _analyzer.calculateRelativeAngle(
        _baseWaistVec!,
        currentW,
      );

      double rawTAngle = _analyzer.calculateRelativeAngle(
        _baseThighVec!,
        currentT,
      );

      // 로우 패스 필터 적용
      double cleanWAngle = _waistFilter.filter(rawWAngle);
      double cleanTAngle = _thighFilter.filter(rawTAngle);

      // 스쿼트 분석
      _data = _analyzer.analyze(
        _data,
        cleanWAngle,
        cleanTAngle,
      );

      notifyListeners();
    } catch (e) {
      print(
        "🚨 상대 각도 연산 및 자세 분석 도중 예외 발생: $e",
      );
    }
  }

  // 가상 센서 각도를 원본 벡터로 변환하여 기존 분석 파이프라인에 전달
  void updateVirtualData({
    required double waistAngle,
    required double thighAngle,
  }) {
    if (!_isReading) return;

    // 각도를 3축 벡터로 변환
    List<double> toVector(double angle) {
      final radian = angle * pi / 180.0;

      return [
        sin(radian),
        0.0,
        cos(radian),
      ];
    }

    final waistVector = toVector(waistAngle);
    final thighVector = toVector(thighAngle);

    // 기존 센서 데이터 처리 함수로 전달
    updateRawData(waistVector, thighVector);
  }

  // 가상 스쿼트 시나리오 랜덤 선택
  void _selectVirtualScenario() {
    final random = Random();
    final value = random.nextInt(100);

    if (value < 60) {
      _currentVirtualScenario = VirtualSquatScenario.normal;
    } else if (value < 70) {
      _currentVirtualScenario = VirtualSquatScenario.waistError;
    } else if (value < 80) {
      _currentVirtualScenario = VirtualSquatScenario.shallow;
    } else if (value < 90) {
      _currentVirtualScenario = VirtualSquatScenario.fast;
    } else {
      _currentVirtualScenario = VirtualSquatScenario.combined;
    }

    print("🎲 선택된 가상 시나리오: $_currentVirtualScenario");
  }

  void startVirtualWorkout() {
    if (_isReading) return;

    startReading();

    _virtualStopwatch = Stopwatch()..start();
    _virtualWorkoutTimer?.cancel();

    double smoothedThighAngle = 0.0;
    double smoothedWaistAngle = 20.0;

    _selectVirtualScenario();

    int cycleStartMs = 0;

    double getCycleDuration() {
      switch (_currentVirtualScenario!) {
        case VirtualSquatScenario.shallow:
          return 5.5;
        case VirtualSquatScenario.combined:
        case VirtualSquatScenario.fast:
          return 3.0;
        case VirtualSquatScenario.normal:
        case VirtualSquatScenario.waistError:
          return 6.0;
      }
    }

    double cycleDuration = getCycleDuration();

    _virtualWorkoutTimer = Timer.periodic(
      const Duration(milliseconds: 16),
          (timer) {
        if (!_isReading || _virtualStopwatch == null) {
          timer.cancel();
          return;
        }

        int now = _virtualStopwatch!.elapsedMilliseconds;

        double elapsed = (now - cycleStartMs) / 1000.0;

        if (elapsed >= cycleDuration) {
          cycleStartMs = now;
          _selectVirtualScenario();
          cycleDuration = getCycleDuration();
          elapsed = 0.0;
        }

        bool isShallow =
            _currentVirtualScenario == VirtualSquatScenario.shallow ||
                _currentVirtualScenario == VirtualSquatScenario.combined;

        bool isFast =
            _currentVirtualScenario == VirtualSquatScenario.fast ||
                _currentVirtualScenario == VirtualSquatScenario.combined;

        bool isWaistError =
            _currentVirtualScenario == VirtualSquatScenario.waistError ||
                _currentVirtualScenario == VirtualSquatScenario.combined;

        double maxThighAngle = isShallow ? 75.0 : 100.0;

        double targetThighAngle = 0.0;
        double targetWaistAngle = 20.0;

        double clampProgress(double value) {
          return value.clamp(0.0, 1.0).toDouble();
        }

        if (isFast) {
          if (elapsed < 0.2) {
            targetThighAngle = 0.0;
          } else if (elapsed < 1.0) {
            double progress =
            clampProgress((elapsed - 0.2) / 0.8);

            targetThighAngle = maxThighAngle * progress;
          } else if (elapsed < 1.1) {
            targetThighAngle = maxThighAngle;
          } else if (elapsed < 1.9) {
            double progress =
            clampProgress((elapsed - 1.1) / 0.8);

            targetThighAngle =
                maxThighAngle * (1.0 - progress);
          } else {
            targetThighAngle = 0.0;
          }
        } else if (isShallow) {
          if (elapsed < 0.2) {
            targetThighAngle = 0.0;
          } else if (elapsed < 2.4) {
            double progress =
            clampProgress((elapsed - 0.2) / 2.2);

            targetThighAngle = maxThighAngle * progress;
          } else if (elapsed < 3.0) {
            targetThighAngle = maxThighAngle;
          } else if (elapsed < 5.2) {
            double progress =
            clampProgress((elapsed - 3.0) / 2.2);

            targetThighAngle =
                maxThighAngle * (1.0 - progress);
          } else {
            targetThighAngle = 0.0;
          }
        } else {
          if (elapsed < 0.3) {
            targetThighAngle = 0.0;
          } else if (elapsed < 2.1) {
            double progress =
            clampProgress((elapsed - 0.3) / 1.8);

            targetThighAngle =
                maxThighAngle * progress * progress;
          } else if (elapsed < 3.3) {
            targetThighAngle = maxThighAngle;
          } else if (elapsed < 5.3) {
            double progress =
            clampProgress((elapsed - 3.3) / 2.0);

            double curve =
                1.0 - (1.0 - progress) * (1.0 - progress);

            targetThighAngle =
                maxThighAngle * (1.0 - curve);
          } else {
            targetThighAngle = 0.0;
          }
        }

        double waistChange = isWaistError ? 55.0 : 30.0;

        targetWaistAngle =
            20.0 + (waistChange * targetThighAngle / maxThighAngle);

        smoothedThighAngle +=
            (targetThighAngle - smoothedThighAngle) * 0.12;

        smoothedWaistAngle +=
            (targetWaistAngle - smoothedWaistAngle) * 0.12;

        updateVirtualData(
          waistAngle: smoothedWaistAngle,
          thighAngle: smoothedThighAngle,
        );
      },
    );
  }

  // 가상 운동 정지
  void stopVirtualWorkout() {
    _virtualWorkoutTimer?.cancel();
    _virtualWorkoutTimer = null;

    _virtualStopwatch?.stop();
    _virtualStopwatch = null;

    _isReading = false;
    notifyListeners();
  }

  // 운동 통계 및 필요 시 영점 초기화
  void resetWorkoutState({bool resetZeroPoint = false}) {
    // 진행 중인 스쿼트 판정 상태 초기화
    _analyzer.resetCurrentRepFlags();

    // 영점 초기화가 요청된 경우
    if (resetZeroPoint) {
      _baseWaistVec = null;
      _baseThighVec = null;

      _waistFilter.reset();
      _thighFilter.reset();
    }

    _data = _data.copyWith(
      totalCount: 0,
      successCount: 0,
      waistErrorCount: 0,
      depthErrorCount: 0,
      fastRepCount: 0,
      waistAngle: resetZeroPoint ? 0.0 : _data.waistAngle,
      thighAngle: resetZeroPoint ? 0.0 : _data.thighAngle,
      status: resetZeroPoint ? "영점 재설정 대기 중" : "운동 기록 초기화",
      currentState: "STAND",
    );

    notifyListeners();
  }

  // 전체 상태 리셋
  void reset() {
    // 가상 운동 타이머 정리
    _virtualWorkoutTimer?.cancel();
    _virtualWorkoutTimer = null;

    _virtualStopwatch?.stop();
    _virtualStopwatch = null;

    _isReading = false;

    _baseWaistVec = null;
    _baseThighVec = null;

    // 필터 상태 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    // Analyzer 상태 초기화
    _analyzer.resetCurrentRepFlags();

    _data = SquatData(
      waistAngle: 0.0,
      thighAngle: 0.0,
      status: "정지됨",
    );

    notifyListeners();
  }

  // 내부 상태 갱신 헬퍼
  void _updateState({
    double? waist,
    double? thigh,
    String? status,
  }) {
    _data = _data.copyWith(
      waistAngle: waist,
      thighAngle: thigh,
      status: status,
    );

    notifyListeners();
  }

  // 현재 운동 세션 기록 저장
  Future<bool> saveCurrentSessionRecord() async {
    // 실제로 완료된 스쿼트가 하나도 없으면 저장하지 않음
    if (_data.totalCount == 0) {
      print("⚠️ 스쿼트 수행 기록이 없어 저장을 스킵합니다.");
      return false;
    }

    try {
      // SquatData → SquatRecord 변환
      final record = SquatRecord.fromSquatData(_data);

      // SQLite DB에 저장
      final savedId =
      await DatabaseHelper.instance.insertRecord(record);

      print(
        "💾 스쿼트 기록이 DB에 성공적으로 저장되었습니다! "
            "(Record ID: $savedId)",
      );

      // 저장 후 현재 카운터만 초기화, 연결 및 영점은 유지
      resetWorkoutState();

      // 최신 기록 다시 불러오기
      await loadLocalRecords();

      return true;
    } catch (e) {
      print("❌ DB 저장 중 에러 발생: $e");
      return false;
    }
  }

  // 로컬 DB 전체 운동 기록 불러오기
  Future<void> loadLocalRecords() async {
    _localRecords =
    await DatabaseHelper.instance.getAllRecords();

    notifyListeners();
  }

  // 특정 로컬 기록의 서버 동기화 상태 변경
  Future<void> updateRecordSyncStatus(int id, bool isSynced) async {
    await DatabaseHelper.instance.updateSyncStatus(id, isSynced);

    // 변경된 최신 기록 목록 다시 불러오기
    await loadLocalRecords();
  }

  // 로컬 운동 기록 전체 삭제
  Future<void> clearLocalRecords() async {
    await DatabaseHelper.instance.deleteAllRecords();

    _localRecords = [];

    notifyListeners();
  }

  // 테스트용 더미 기록 생성
  Future<void> generateDummyRecords() async {
    try {
      // 더미 데이터 생성
      await DatabaseHelper.instance.insertDummyRecords();

      // 최신 데이터 다시 불러오기
      await loadLocalRecords();

      print(
        "🧪 스쿼트 더미 데이터 30개 생성 완료 및 홈 화면 UI 갱신 방송 송출!",
      );
    } catch (e) {
      print("❌ 더미 데이터 생성 중 에러 발생: $e");
    }
  }
}