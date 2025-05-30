import 'package:flutter/material.dart';
import '../screens/add_item_screen.dart';
import '../utils/app_theme.dart';

class CustomFloatingActionButtons extends StatefulWidget {
  const CustomFloatingActionButtons({super.key});

  @override
  State<CustomFloatingActionButtons> createState() =>
      _CustomFloatingActionButtonsState();
}

class _CustomFloatingActionButtonsState
    extends State<CustomFloatingActionButtons>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _navigateToAddItem({bool useVoice = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(initialVoiceMode: useVoice),
      ),
    );
    if (_isExpanded) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 음성 입력 버튼
        ScaleTransition(
          scale: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: "voice_fab",
              onPressed: () => _navigateToAddItem(useVoice: true),
              backgroundColor: AppTheme.secondaryPastel,
              elevation: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.secondaryPastel,
                      AppTheme.secondaryPastel.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        // 텍스트 입력 버튼
        ScaleTransition(
          scale: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              heroTag: "text_fab",
              onPressed: () => _navigateToAddItem(useVoice: false),
              backgroundColor: AppTheme.accentPastel,
              elevation: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentPastel,
                      AppTheme.accentPastel.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        // 메인 버튼
        FloatingActionButton(
          heroTag: "main_fab",
          onPressed: _toggle,
          backgroundColor: AppTheme.primaryPastel,
          elevation: 12,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPastel,
                        AppTheme.primaryPastel.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
