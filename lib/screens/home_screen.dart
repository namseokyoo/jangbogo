import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/shopping_provider.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/custom_floating_action_buttons.dart';
import '../widgets/filter_bar.dart';
import '../widgets/stats_card.dart';
import '../utils/app_theme.dart';
import 'add_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 16),
              _buildFilterBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildItemsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: const CustomFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _buildBottomAppBar(),
      appBar: AppBar(title: Text('장보고왔다')),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPastel.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕하세요! 👋',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                    Text(
                      '장보고왔다',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSettingsMenu(context),
                icon: const Icon(Icons.more_vert, color: AppTheme.grey600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<ShoppingProvider>().setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: '구매할 물건을 검색하세요',
          prefixIcon: const Icon(Icons.search, color: AppTheme.grey400),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<ShoppingProvider>().setSearchQuery('');
                    },
                    icon: const Icon(Icons.clear, color: AppTheme.grey400),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: '할 일',
                  count: provider.pendingCount,
                  color: AppTheme.primary,
                  icon: Icons.shopping_cart_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: '완료',
                  count: provider.completedCount,
                  color: AppTheme.success,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: '전체',
                  count: provider.totalCount,
                  color: AppTheme.secondary,
                  icon: Icons.list_alt,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return const FilterBar();
  }

  Widget _buildItemsList() {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.filteredItems.isEmpty) {
          return _buildEmptyState();
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: provider.filteredItems.length,
            itemBuilder: (context, index) {
              final item = provider.filteredItems[index];

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShoppingItemTile(
                        item: item,
                        onToggle: () => provider.toggleItemComplete(item.id),
                        onDelete:
                            () => _showDeleteConfirmation(context, item.id),
                        onEdit: () => _showEditDialog(context, item),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryPastel.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '구매할 물건이 없어요',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 번째 아이템을 추가해보세요!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.grey500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddItem(context),
            icon: const Icon(Icons.add),
            label: const Text('아이템 추가하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: AppTheme.white,
      elevation: 8,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _showPeriodSelector(context),
              icon: const Icon(Icons.date_range, color: AppTheme.grey600),
              tooltip: '기간 선택',
            ),
            IconButton(
              onPressed: () => _showSortMenu(context),
              icon: const Icon(Icons.sort, color: AppTheme.grey600),
              tooltip: '정렬',
            ),
            const SizedBox(width: 40), // FAB를 위한 공간
          ],
        ),
      ),
    );
  }

  void _navigateToAddItem(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddItemScreen()));
  }

  void _showDeleteConfirmation(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('삭제 확인'),
            content: const Text('이 아이템을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  context.read<ShoppingProvider>().deleteItem(itemId);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(BuildContext context, item) {
    // TODO: 편집 다이얼로그 구현
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: AppTheme.error),
            title: const Text('완료된 아이템 모두 삭제'),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteCompletedConfirmation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: AppTheme.primary),
            title: const Text('새로고침'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<ShoppingProvider>().refresh();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteCompletedConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('완료된 아이템 삭제'),
            content: const Text('완료된 모든 아이템을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  context.read<ShoppingProvider>().deleteCompletedItems();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showPeriodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildPeriodSelector(),
    );
  }

  Widget _buildPeriodSelector() {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('조회 기간', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildPeriodOption(
                context,
                PeriodType.today,
                '오늘',
                provider.currentPeriod,
              ),
              _buildPeriodOption(
                context,
                PeriodType.week,
                '이번 주',
                provider.currentPeriod,
              ),
              _buildPeriodOption(
                context,
                PeriodType.month,
                '이번 달',
                provider.currentPeriod,
              ),
              _buildPeriodOption(
                context,
                PeriodType.year,
                '올해',
                provider.currentPeriod,
              ),
              _buildPeriodOption(
                context,
                PeriodType.all,
                '전체',
                provider.currentPeriod,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(
    BuildContext context,
    PeriodType period,
    String title,
    PeriodType currentPeriod,
  ) {
    final isSelected = period == currentPeriod;

    return ListTile(
      title: Text(title),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
      onTap: () {
        context.read<ShoppingProvider>().setPeriod(period);
        Navigator.of(context).pop();
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortMenu(),
    );
  }

  Widget _buildSortMenu() {
    return Consumer<ShoppingProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정렬 방식', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildSortOption(
                context,
                SortType.newest,
                '최신순',
                provider.currentSort,
              ),
              _buildSortOption(
                context,
                SortType.oldest,
                '오래된순',
                provider.currentSort,
              ),
              _buildSortOption(
                context,
                SortType.alphabetical,
                '가나다순',
                provider.currentSort,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    SortType sort,
    String title,
    SortType currentSort,
  ) {
    final isSelected = sort == currentSort;

    return ListTile(
      title: Text(title),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
      onTap: () {
        context.read<ShoppingProvider>().setSort(sort);
        Navigator.of(context).pop();
      },
    );
  }
}
