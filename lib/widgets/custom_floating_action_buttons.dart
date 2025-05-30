import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/add_item_modal.dart';

class CustomFloatingActionButtons extends StatelessWidget {
  const CustomFloatingActionButtons({super.key});

  void _openAddItemModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddItemModal(),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "main_fab",
      onPressed: () => _openAddItemModal(context),
      backgroundColor: AppTheme.primaryPastel,
      elevation: 12,
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
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
