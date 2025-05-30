import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../services/speech_service.dart';
import '../utils/app_theme.dart';
import '../models/shopping_item.dart';

class AddItemScreen extends StatefulWidget {
  final bool initialVoiceMode;

  const AddItemScreen({super.key, this.initialVoiceMode = false});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  bool _isVoiceMode = false;
  String _selectedCategory = '기타';
  bool _showAdvancedOptions = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _categories = [
    '식료품',
    '생활용품',
    '의류',
    '전자제품',
    '화장품',
    '도서',
    '스포츠',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _isVoiceMode = widget.initialVoiceMode;
    _initializeSpeech();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 음성 모드로 시작해도 자동으로 음성 인식을 시작하지 않음
    // 사용자가 수동으로 "음성 인식 시작" 버튼을 눌러야 함
  }

  @override
  void dispose() {
    _textController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _textFocusNode.dispose();
    _pulseController.dispose();

    // 음성 인식 중이면 중지
    if (_isListening) {
      _speechService.stopListening();
    }

    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
  }

  Future<void> _startListening() async {
    final isAvailable = await _speechService.isAvailable();
    if (!isAvailable) {
      _showErrorSnackBar('음성 인식을 사용할 수 없습니다.');
      return;
    }

    setState(() {
      _isListening = true;
    });

    _pulseController.repeat(reverse: true);

    try {
      await _speechService.startListening(
        onResult: (result) {
          if (result.isNotEmpty) {
            setState(() {
              _textController.text = result;
            });
          }
        },
      );
    } catch (e) {
      _showErrorSnackBar('음성 인식 중 오류가 발생했습니다: $e');
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
    }
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addItems() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackBar('아이템을 입력해주세요.');
      return;
    }

    final provider = Provider.of<ShoppingProvider>(context, listen: false);

    // 공백으로 구분하여 여러 아이템 처리
    final itemNames = text.split(' ').where((name) => name.isNotEmpty).toList();

    if (itemNames.isEmpty) {
      _showErrorSnackBar('유효한 아이템을 입력해주세요.');
      return;
    }

    try {
      for (final itemName in itemNames) {
        await provider.addItem(
          itemName.trim(),
          notes:
              _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
          category: _selectedCategory,
          price:
              _priceController.text.trim().isEmpty
                  ? null
                  : double.tryParse(_priceController.text.trim()),
          quantity:
              _quantityController.text.trim().isEmpty
                  ? 1
                  : int.tryParse(_quantityController.text.trim()) ?? 1,
        );
      }

      _showSuccessSnackBar('${itemNames.length}개의 아이템이 추가되었습니다.');

      // 입력 필드 초기화
      _textController.clear();
      _notesController.clear();
      _priceController.clear();
      _quantityController.clear();

      // 포커스를 텍스트 필드로 이동
      if (!_isVoiceMode) {
        _textFocusNode.requestFocus();
      }
    } catch (e) {
      _showErrorSnackBar('아이템 추가 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '아이템 추가',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 음성/텍스트 모드 전환 버튼
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _isVoiceMode
                          ? AppTheme.secondary.withOpacity(0.2)
                          : AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isVoiceMode ? Icons.keyboard : Icons.mic,
                  color: _isVoiceMode ? AppTheme.secondary : AppTheme.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isVoiceMode = !_isVoiceMode;
                });
                if (_isVoiceMode) {
                  // 음성 모드로 전환시 자동으로 음성 인식 시작하지 않음
                  // 사용자가 수동으로 시작하도록 변경
                } else {
                  _stopListening();
                  _textFocusNode.requestFocus();
                }
              },
              tooltip: _isVoiceMode ? '텍스트 입력 모드로 전환' : '음성 입력 모드로 전환',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 음성 모드 표시 (더 눈에 띄게)
              if (_isVoiceMode) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.secondary.withOpacity(0.1),
                        AppTheme.primary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isListening ? AppTheme.error : AppTheme.secondary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isListening)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.error,
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.mic,
                                      color: AppTheme.error,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.grey300,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.grey500,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.mic_off,
                                color: AppTheme.grey600,
                                size: 30,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isListening ? '🎤 음성 인식 중...' : '🎤 음성 모드',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color:
                                      _isListening
                                          ? AppTheme.error
                                          : AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isListening
                                    ? '말씀하세요. 종료하려면 정지 버튼을 누르세요.'
                                    : '시작 버튼을 눌러 음성 인식을 시작하세요.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.grey600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                            icon: Icon(
                              _isListening ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isListening ? '음성 인식 중지' : '음성 인식 시작',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isListening
                                      ? AppTheme.error
                                      : AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isVoiceMode = false;
                                if (_isListening) {
                                  _stopListening();
                                }
                              });
                              _textFocusNode.requestFocus();
                            },
                            icon: Icon(Icons.keyboard, color: AppTheme.primary),
                            label: Text(
                              '텍스트 모드',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 입력 모드 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.grey200.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isVoiceMode ? Icons.mic : Icons.keyboard,
                      color:
                          _isVoiceMode ? AppTheme.secondary : AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isVoiceMode ? '음성 입력 모드' : '텍스트 입력 모드',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            _isVoiceMode
                                ? AppTheme.secondary
                                : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_isListening)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 아이템 입력 필드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.grey200.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '아이템 이름',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      decoration: InputDecoration(
                        hintText: '아이템을 입력하세요 (공백으로 구분하여 여러 개 입력 가능)',
                        suffixIcon:
                            _isVoiceMode
                                ? IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.stop : Icons.mic,
                                    color:
                                        _isListening
                                            ? AppTheme.error
                                            : AppTheme.secondary,
                                  ),
                                  onPressed:
                                      _isListening
                                          ? _stopListening
                                          : _startListening,
                                )
                                : null,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),

                    const SizedBox(height: 16),

                    // 카테고리 선택
                    Text(
                      '카테고리',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 고급 옵션 토글
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                icon: Icon(
                  _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primary,
                ),
                label: Text('고급 옵션', style: TextStyle(color: AppTheme.primary)),
              ),

              // 고급 옵션
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.grey200.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 메모
                      Text(
                        '메모',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: '추가 메모를 입력하세요',
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      // 가격과 수량
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '가격',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _priceController,
                                  decoration: const InputDecoration(
                                    hintText: '가격',
                                    prefixText: '₩ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '수량',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 추가 버튼
              ElevatedButton(
                onPressed: _addItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  '아이템 추가',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 도움말
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPastel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPastel.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '사용 팁',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 여러 아이템을 한 번에 추가하려면 공백으로 구분하여 입력하세요\n'
                      '• 음성 입력 모드에서는 자연스럽게 말해주세요\n'
                      '• 카테고리를 설정하면 나중에 필터링할 수 있습니다',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
