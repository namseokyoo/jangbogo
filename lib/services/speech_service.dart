import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidenceLevel = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidenceLevel => _confidenceLevel;

  // 음성 인식 초기화
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 마이크 권한 요청
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        throw Exception('마이크 권한이 필요합니다.');
      }

      // 음성 인식 초기화
      _isInitialized = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );

      return _isInitialized;
    } catch (e) {
      print('음성 인식 초기화 실패: $e');
      return false;
    }
  }

  // 음성 인식 시작
  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('음성 인식을 초기화할 수 없습니다.');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidenceLevel = result.confidence;

          if (result.finalResult) {
            onResult(_lastWords);
          }
        },
        listenFor: const Duration(minutes: 30), // 30분으로 확장 (거의 무제한)
        pauseFor: const Duration(seconds: 10), // 긴 침묵 허용
        partialResults: true,
        localeId: localeId ?? 'ko_KR', // 기본값은 한국어
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: false, // 에러시에도 계속 유지
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
    } catch (e) {
      print('음성 인식 시작 실패: $e');
      throw Exception('음성 인식을 시작할 수 없습니다: $e');
    }
  }

  // 음성 인식 중지
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  // 음성 인식 취소
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      _confidenceLevel = 0.0;
    }
  }

  // 사용 가능한 로케일 목록 조회
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  // 음성 인식 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }

  // 텍스트를 구매 목록으로 파싱 (띄어쓰기 기준으로 분리)
  List<String> parseShoppingItems(String text) {
    if (text.isEmpty) return [];

    // 텍스트 정제
    String cleanedText = text.trim();

    // 특수 문자 제거 및 정제
    cleanedText =
        cleanedText
            .replaceAll(RegExp(r'[.,!?;:]'), ' ') // 특수 문자를 공백으로 대체
            .replaceAll(RegExp(r'\s+'), ' ') // 연속된 공백을 하나로 합치기
            .trim();

    // 띄어쓰기로 분리
    List<String> items =
        cleanedText
            .split(' ')
            .where((item) => item.isNotEmpty)
            .map((item) => item.trim())
            .where((item) => item.length > 0)
            .toList();

    // 중복 제거
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

  // 에러 핸들링
  void _onError(error) {
    print('음성 인식 에러: $error');
    _isListening = false;
  }

  // 상태 변경 핸들링
  void _onStatus(String status) {
    print('음성 인식 상태: $status');

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

  // 음성 레벨 변경 핸들링
  void _onSoundLevelChange(double level) {
    // 음성 레벨 변경 시 처리할 로직 (필요시 구현)
  }

  // 리소스 정리
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
