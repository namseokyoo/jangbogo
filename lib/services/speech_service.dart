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
  double _soundLevel = 0.0;

  // 음성 레벨 변경 콜백 추가
  Function(double)? _soundLevelCallback;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidenceLevel => _confidenceLevel;
  double get soundLevel => _soundLevel;

  // 음성 인식 초기화 (재시도 로직 추가)
  Future<bool> initialize() async {
    try {
      // 이미 초기화되어 있으면 성공 반환
      if (_isInitialized) return true;

      // 마이크 권한 요청
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        // 권한이 거부되면 설정으로 유도
        if (permissionStatus == PermissionStatus.permanentlyDenied) {
          throw Exception('마이크 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        }
        throw Exception('마이크 권한이 필요합니다.');
      }

      // 음성 인식 초기화 (재시도 로직)
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _isInitialized = await _speechToText.initialize(
            onError: _onError,
            onStatus: _onStatus,
            debugLogging: false,
          );

          if (_isInitialized) {
            print('음성 인식 초기화 성공 (시도: $attempt)');
            return true;
          }
        } catch (e) {
          print('음성 인식 초기화 시도 $attempt 실패: $e');
          if (attempt < 3) {
            // 잠시 대기 후 재시도
            await Future.delayed(Duration(milliseconds: 500 * attempt));
          }
        }
      }

      throw Exception('음성 인식을 초기화할 수 없습니다. 다시 시도해주세요.');
    } catch (e) {
      print('음성 인식 초기화 실패: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // 음성 인식 시작
  Future<void> startListening({
    required Function(String) onResult,
    Function(double)? onSoundLevel,
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

    // 음성 레벨 콜백 설정
    _soundLevelCallback = onSoundLevel;

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
        onSoundLevelChange: _handleSoundLevelChange,
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

  // 음성 인식 사용 가능 여부 확인 (개선된 버전)
  Future<bool> isAvailable() async {
    try {
      // 이미 초기화되어 있으면 사용 가능
      if (_isInitialized) {
        return true;
      }

      // 초기화되지 않았으면 초기화 시도
      final available = await _speechToText.initialize();
      if (available) {
        _isInitialized = true;
      }
      return available;
    } catch (e) {
      print('음성 인식 사용 가능 여부 확인 실패: $e');
      return false;
    }
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
  void _handleSoundLevelChange(double level) {
    _soundLevel = level;
    // 등록된 콜백이 있으면 호출
    if (_soundLevelCallback != null) {
      _soundLevelCallback!(level);
    }
  }

  // 리소스 정리
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
