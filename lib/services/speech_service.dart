import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidenceLevel = 0.0;
  double _soundLevel = 0.0;

  // 콜백 함수들
  Function(String)? _onResultCallback;
  Function(double)? _soundLevelCallback;

  // Getter들
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidenceLevel => _confidenceLevel;
  double get soundLevel => _soundLevel;

  // 음성 인식 초기화 (간단하고 안정적으로)
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        return true;
      }

      print('🎤 음성 인식 초기화 시작...');

      // 간단한 초기화
      final available = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
      );

      if (available) {
        _isInitialized = true;
        print('✅ 음성 인식 초기화 성공');

        // 웹에서 사용 가능한 로케일 확인
        if (kIsWeb) {
          try {
            final locales = await _speechToText.locales();
            print('📍 사용 가능한 로케일: ${locales.length}개');
          } catch (e) {
            print('⚠️ 로케일 확인 실패: $e');
          }
        }
      } else {
        print('❌ 음성 인식을 사용할 수 없습니다');
      }

      return available;
    } catch (e) {
      print('🚨 음성 인식 초기화 실패: $e');
      return false;
    }
  }

  // 음성 인식 시작 (안정성 강화)
  Future<void> startListening({
    required Function(String) onResult,
    Function(double)? onSoundLevel,
    String? localeId,
  }) async {
    print('🎯 음성 인식 시작 요청...');

    if (!_isInitialized) {
      print('🔄 초기화되지 않음 - 재초기화 시도');
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('음성 인식을 초기화할 수 없습니다');
      }
    }

    // 이미 실행 중이면 완전히 정지
    if (_isListening) {
      print('⚠️ 이미 음성인식 실행 중 - 완전 정지 후 재시작');
      await _forceStop();
    }

    _onResultCallback = onResult;
    _soundLevelCallback = onSoundLevel;

    try {
      print('🚀 음성 인식 시작 중...');

      // 웹에서 안정적인 설정
      final success = await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidenceLevel = result.confidence;

          print(
              '💬 인식 결과: "${result.recognizedWords}" (신뢰도: ${(result.confidence * 100).toStringAsFixed(1)}%)');

          // 실시간 결과 전달
          if (_onResultCallback != null) {
            _onResultCallback!(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30), // 웹에서는 더 짧게 (30초)
        pauseFor: const Duration(seconds: 1), // 웹에서는 더 짧게 (1초)
        partialResults: true,
        localeId: localeId ?? 'ko_KR',
        onSoundLevelChange: (level) {
          _soundLevel = level;
          if (_soundLevelCallback != null) {
            _soundLevelCallback!(level);
          }
        },
        cancelOnError: true, // 에러 시 자동 취소
        listenMode: ListenMode.confirmation,
      );

      if (success) {
        _isListening = true;
        print('✅ 음성 인식 시작 성공');
      } else {
        print('❌ 음성 인식 시작 실패');
        throw Exception('음성 인식을 시작할 수 없습니다');
      }
    } catch (e) {
      print('🚨 음성 인식 시작 실패: $e');
      _isListening = false;
      throw Exception(_getErrorMessage(e.toString()));
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (!_isListening) return;

    print('🛑 음성 인식 중지...');

    try {
      await _speechToText.stop();
      print('✅ 음성 인식 중지 완료');
    } catch (e) {
      print('⚠️ 음성 인식 중지 중 오류: $e');
    } finally {
      _isListening = false;
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (!_isListening) return;

    print('❌ 음성 인식 취소...');

    try {
      await _speechToText.cancel();
      print('✅ 음성 인식 취소 완료');
    } catch (e) {
      print('⚠️ 음성 인식 취소 중 오류: $e');
    } finally {
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
    }
  }

  // 강제 정지 (웹 안정성용)
  Future<void> _forceStop() async {
    print('🔄 음성 인식 강제 정지...');

    try {
      // 모든 정지 방법 시도
      await _speechToText.cancel();
      await Future.delayed(const Duration(milliseconds: 200));
      await _speechToText.stop();
      await Future.delayed(const Duration(milliseconds: 500)); // 웹에서는 충분한 대기
    } catch (e) {
      print('⚠️ 강제 정지 중 오류 (무시됨): $e');
    } finally {
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
      _soundLevel = 0.0;
      print('✅ 강제 정지 완료');
    }
  }

  // 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    try {
      if (!_isInitialized) {
        return await initialize();
      }
      return _speechToText.isAvailable;
    } catch (e) {
      print('🚨 음성 인식 사용 가능 여부 확인 실패: $e');
      return false;
    }
  }

  // 에러 메시지 생성
  String _getErrorMessage(String error) {
    if (error.contains('permission') || error.contains('not-allowed')) {
      return '마이크 권한이 필요합니다. 브라우저에서 마이크 사용을 허용해주세요';
    } else if (error.contains('network')) {
      return '네트워크 연결을 확인해주세요';
    } else if (error.contains('no-speech')) {
      return '음성이 감지되지 않았습니다. 마이크 가까이에서 다시 시도해주세요';
    } else if (error.contains('audio-capture')) {
      return '마이크에 문제가 있습니다. 마이크 연결을 확인해주세요';
    } else if (error.contains('already')) {
      return '잠시 후 다시 시도해주세요';
    } else {
      return '음성 인식을 사용할 수 없습니다. 브라우저 설정을 확인해주세요';
    }
  }

  // 에러 핸들링
  void _onError(SpeechRecognitionError error) {
    print('🚨 음성 인식 에러: ${error.errorMsg} (영구: ${error.permanent})');
    _isListening = false;

    // 영구적인 에러면 초기화 상태 리셋
    if (error.permanent) {
      _isInitialized = false;
    }
  }

  // 상태 변경 핸들링
  void _onStatus(String status) {
    print('📊 음성 인식 상태: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        break;
    }
  }

  // 텍스트 파싱
  List<String> parseShoppingItems(String text) {
    if (text.isEmpty) return [];

    String cleanedText = text
        .trim()
        .replaceAll(RegExp(r'[.,!?;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    List<String> items = cleanedText
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) => item.trim())
        .where((item) => item.length > 0)
        .toList();

    return items.toSet().toList();
  }

  // 일반적인 구매 목록 키워드 감지 및 정제
  List<String> enhanceShoppingItems(List<String> items) {
    const Map<String, String> synonyms = {
      // 식품류
      '쌀': '쌀',
      '밥': '쌀',
      '라면': '라면',
      '면': '라면',
      '우유': '우유',
      '물': '물',
      '음료': '음료수',

      // 채소류
      '양파': '양파',
      '당근': '당근',
      '감자': '감자',
      '배추': '배추',
      '상추': '상추',

      // 과일류
      '사과': '사과',
      '바나나': '바나나',
      '오렌지': '오렌지',
      '포도': '포도',

      // 생활용품
      '휴지': '휴지',
      '세제': '세제',
      '샴푸': '샴푸',
      '비누': '비누',
      '치약': '치약',
      '칫솔': '칫솔',
    };

    return items.map((item) {
      String lowerItem = item.toLowerCase();

      // 동의어 변환
      for (String key in synonyms.keys) {
        if (lowerItem.contains(key)) {
          return synonyms[key]!;
        }
      }

      return item;
    }).toList();
  }

  // 리소스 정리
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
