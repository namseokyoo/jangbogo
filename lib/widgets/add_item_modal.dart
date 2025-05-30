import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../services/speech_service.dart';
import '../utils/app_theme.dart';

class AddItemModal extends StatefulWidget {
  const AddItemModal({super.key});

  @override
  State<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends State<AddItemModal>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  String _selectedCategory = '기타';
  bool _showAdvancedOptions = false;
  double _soundLevel = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _soundLevelController;
  late Animation<double> _soundLevelAnimation;

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
    _initializeSpeech();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _soundLevelController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _soundLevelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _soundLevelController, curve: Curves.easeOut),
    );

    // 텍스트 필드에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _textFocusNode.dispose();
    _pulseController.dispose();
    _soundLevelController.dispose();

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
        onSoundLevel: (level) {
          setState(() {
            _soundLevel = level;
          });
          // 음성 레벨에 따른 애니메이션
          _soundLevelController.animateTo(level.clamp(0.0, 1.0));
        },
      );
    } catch (e) {
      _showErrorSnackBar('음성 인식 중 오류가 발생했습니다: $e');
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
      _soundLevelController.reset();
    }
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
    _pulseController.stop();
    _soundLevelController.reset();
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

      // 모달 닫기
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('아이템 추가 중 오류가 발생했습니다: $e');
    }
  }

  Widget _buildSoundLevelIndicator() {
    return AnimatedBuilder(
      animation: _soundLevelAnimation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppTheme.secondary, AppTheme.error],
              stops: [0.0, _soundLevelAnimation.value],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '아이템 추가',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

            // 컨텐츠
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 음성 인식 상태 표시 (음성 모드일 때만)
                    if (_isListening) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.error.withOpacity(0.1),
                              AppTheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error, width: 2),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Icon(
                                    Icons.mic,
                                    color: AppTheme.error,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎤 음성 인식 중...',
                                    style: TextStyle(
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '말씀하시면 자동으로 입력됩니다',
                                    style: TextStyle(
                                      color: AppTheme.grey600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 음성 레벨 표시기
                            Row(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 2),
                                  width: 4,
                                  height: 20 + (index * 5),
                                  decoration: BoxDecoration(
                                    color:
                                        _soundLevel > (index * 0.2)
                                            ? AppTheme.error
                                            : AppTheme.grey300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 아이템 입력 필드
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color:
                                _isListening
                                    ? AppTheme.error
                                    : AppTheme.secondary,
                          ),
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          tooltip: _isListening ? '음성 인식 중지' : '음성 인식 시작',
                        ),
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

                    const SizedBox(height: 16),

                    // 고급 옵션 토글
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                      icon: Icon(
                        _showAdvancedOptions
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppTheme.primary,
                      ),
                      label: Text(
                        '고급 옵션',
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),

                    // 고급 옵션
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
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

                    const SizedBox(height: 24),

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
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
