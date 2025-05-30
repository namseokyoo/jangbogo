import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../services/database_service.dart';
import '../services/speech_service.dart';

enum FilterType { all, pending, completed }

enum SortType { newest, oldest, alphabetical }

enum PeriodType { today, week, month, year, all }

class ShoppingProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final SpeechService _speechService = SpeechService();
  final Uuid _uuid = const Uuid();

  // 상태 변수들
  List<ShoppingItem> _allItems = [];
  List<ShoppingItem> _filteredItems = [];
  FilterType _currentFilter = FilterType.all;
  SortType _currentSort = SortType.newest;
  PeriodType _currentPeriod = PeriodType.all;
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  Map<String, int> _statistics = {};

  // Getters
  List<ShoppingItem> get filteredItems => _filteredItems;
  List<ShoppingItem> get allItems => _allItems;
  FilterType get currentFilter => _currentFilter;
  SortType get currentSort => _currentSort;
  PeriodType get currentPeriod => _currentPeriod;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  Map<String, int> get statistics => _statistics;

  // 편의 Getters
  List<ShoppingItem> get pendingItems =>
      _allItems.where((item) => !item.isCompleted).toList();
  List<ShoppingItem> get completedItems =>
      _allItems.where((item) => item.isCompleted).toList();
  int get totalCount => _allItems.length;
  int get pendingCount => pendingItems.length;
  int get completedCount => completedItems.length;

  // 초기화
  Future<void> initialize() async {
    _setLoading(true);
    await loadItems();
    await updateStatistics();
    _setLoading(false);
  }

  // 모든 아이템 로드
  Future<void> loadItems() async {
    try {
      switch (_currentPeriod) {
        case PeriodType.today:
          _allItems = await _databaseService.getTodayShoppingItems();
          break;
        case PeriodType.week:
          _allItems = await _databaseService.getThisWeekShoppingItems();
          break;
        case PeriodType.month:
          _allItems = await _databaseService.getThisMonthShoppingItems();
          break;
        case PeriodType.year:
          _allItems = await _databaseService.getThisYearShoppingItems();
          break;
        case PeriodType.all:
        default:
          _allItems = await _databaseService.getAllShoppingItems();
          break;
      }
      _applyFiltersAndSort();
    } catch (e) {
      print('아이템 로드 실패: $e');
    }
  }

  // 필터 및 정렬 적용
  void _applyFiltersAndSort() {
    List<ShoppingItem> items = List.from(_allItems);

    // 검색 필터 적용
    if (_searchQuery.isNotEmpty) {
      items =
          items
              .where(
                (item) =>
                    item.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (item.notes?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (item.category?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    // 카테고리 필터 적용
    if (_selectedCategory != null) {
      items =
          items.where((item) => item.category == _selectedCategory).toList();
    }

    // 완료 상태 필터 적용
    switch (_currentFilter) {
      case FilterType.pending:
        items = items.where((item) => !item.isCompleted).toList();
        break;
      case FilterType.completed:
        items = items.where((item) => item.isCompleted).toList();
        break;
      case FilterType.all:
        break;
    }

    // 정렬 적용
    switch (_currentSort) {
      case SortType.newest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.oldest:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.alphabetical:
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    _filteredItems = items;
    notifyListeners();
  }

  // 새 아이템 추가
  Future<void> addItem(
    String name, {
    String? notes,
    String? category,
    double? price,
    int? quantity,
  }) async {
    try {
      final item = ShoppingItem(
        id: _uuid.v4(),
        name: name.trim(),
        createdAt: DateTime.now(),
        notes: notes?.trim(),
        category: category?.trim(),
        price: price,
        quantity: quantity,
      );

      await _databaseService.insertShoppingItem(item);
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('아이템 추가 실패: $e');
    }
  }

  // 여러 아이템 일괄 추가
  Future<void> addItems(List<String> names, {String? category}) async {
    try {
      final items =
          names
              .map(
                (name) => ShoppingItem(
                  id: _uuid.v4(),
                  name: name.trim(),
                  createdAt: DateTime.now(),
                  category: category?.trim(),
                ),
              )
              .toList();

      await _databaseService.insertShoppingItems(items);
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('아이템들 추가 실패: $e');
    }
  }

  // 음성으로 아이템 추가
  Future<void> addItemsFromSpeech(String speechText, {String? category}) async {
    try {
      final itemNames = _speechService.parseShoppingItems(speechText);
      final enhancedNames = _speechService.enhanceShoppingItems(itemNames);

      if (enhancedNames.isNotEmpty) {
        await addItems(enhancedNames, category: category);
      }
    } catch (e) {
      print('음성 아이템 추가 실패: $e');
    }
  }

  // 아이템 업데이트
  Future<void> updateItem(ShoppingItem item) async {
    try {
      await _databaseService.updateShoppingItem(item);
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('아이템 업데이트 실패: $e');
    }
  }

  // 아이템 완료 상태 토글
  Future<void> toggleItemComplete(String itemId) async {
    try {
      await _databaseService.toggleShoppingItemComplete(itemId);
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('아이템 완료 상태 변경 실패: $e');
    }
  }

  // 아이템 삭제
  Future<void> deleteItem(String itemId) async {
    try {
      await _databaseService.deleteShoppingItem(itemId);
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('아이템 삭제 실패: $e');
    }
  }

  // 완료된 아이템들 일괄 삭제
  Future<void> deleteCompletedItems() async {
    try {
      await _databaseService.deleteCompletedItems();
      await loadItems();
      await updateStatistics();
    } catch (e) {
      print('완료된 아이템들 삭제 실패: $e');
    }
  }

  // 필터 변경
  void setFilter(FilterType filter) {
    _currentFilter = filter;
    _applyFiltersAndSort();
  }

  // 정렬 변경
  void setSort(SortType sort) {
    _currentSort = sort;
    _applyFiltersAndSort();
  }

  // 기간 변경
  Future<void> setPeriod(PeriodType period) async {
    _currentPeriod = period;
    _setLoading(true);
    await loadItems();
    _setLoading(false);
  }

  // 검색
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  // 카테고리 필터
  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  // 카테고리 목록 조회
  Future<List<String>> getCategories() async {
    return await _databaseService.getAllCategories();
  }

  // 통계 업데이트
  Future<void> updateStatistics() async {
    try {
      _statistics = await _databaseService.getStatistics();
      notifyListeners();
    } catch (e) {
      print('통계 업데이트 실패: $e');
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 새로고침
  Future<void> refresh() async {
    _setLoading(true);
    await loadItems();
    await updateStatistics();
    _setLoading(false);
  }

  // 검색 결과 조회
  Future<void> searchItems(String query) async {
    try {
      if (query.isEmpty) {
        await loadItems();
      } else {
        _allItems = await _databaseService.searchShoppingItems(query);
        _applyFiltersAndSort();
      }
    } catch (e) {
      print('검색 실패: $e');
    }
  }

  // 필터 및 검색 초기화
  void clearFilters() {
    _currentFilter = FilterType.all;
    _searchQuery = '';
    _selectedCategory = null;
    _applyFiltersAndSort();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
