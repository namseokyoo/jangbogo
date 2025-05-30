import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shopping_item.dart';
import '../utils/app_theme.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppTheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: AppTheme.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('삭제 확인'),
                    content: Text('${item.name}을(를) 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          '삭제',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) => onDelete(),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isCompleted ? AppTheme.success : AppTheme.white,
                  border: Border.all(
                    color:
                        item.isCompleted ? AppTheme.success : AppTheme.grey300,
                    width: 2,
                  ),
                ),
                child:
                    item.isCompleted
                        ? const Icon(
                          Icons.check,
                          color: AppTheme.white,
                          size: 16,
                        )
                        : null,
              ),
            ),
            title: Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration:
                    item.isCompleted ? TextDecoration.lineThrough : null,
                color: item.isCompleted ? AppTheme.grey500 : AppTheme.grey800,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.grey600),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPastel.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category!,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.price != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₩${NumberFormat('#,###').format(item.price!.toInt())}',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.quantity != null && item.quantity! > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}개',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        DateFormat('MM/dd HH:mm').format(item.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.grey500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.grey400),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                  case 'toggle':
                    onToggle();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted ? Icons.undo : Icons.check,
                            color: AppTheme.grey600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(item.isCompleted ? '미완료로 변경' : '완료로 변경'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.grey600, size: 20),
                          SizedBox(width: 8),
                          Text('편집'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.error, size: 20),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: AppTheme.error)),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );
  }
}
