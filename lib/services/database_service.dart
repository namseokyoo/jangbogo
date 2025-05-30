import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shopping_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static SharedPreferences? _prefs;

  Future<void> _initWeb() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Database> get database async {
    if (kIsWeb) {
      await _initWeb();
      throw UnimplementedError('웹에서는 SharedPreferences를 사용합니다');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'janbogo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        category TEXT,
        price REAL,
        quantity INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at ON shopping_items(createdAt);
    ''');

    await db.execute('''
      CREATE INDEX idx_is_completed ON shopping_items(isCompleted);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 향후 데이터베이스 업그레이드 로직 구현
  }

  // 웹용 데이터 로드
  Future<List<ShoppingItem>> _loadFromWeb() async {
    if (kIsWeb) {
      await _initWeb();
      final String? itemsJson = _prefs!.getString('shopping_items');
      if (itemsJson != null) {
        final List<dynamic> jsonList = json.decode(itemsJson);
        return jsonList.map((json) => ShoppingItem.fromJson(json)).toList();
      }
    }
    return [];
  }

  // 웹용 데이터 저장
  Future<void> _saveToWeb(List<ShoppingItem> items) async {
    if (kIsWeb) {
      await _initWeb();
      final String itemsJson = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      await _prefs!.setString('shopping_items', itemsJson);
    }
  }

  // 구매 목록 아이템 추가
  Future<int> insertShoppingItem(ShoppingItem item) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      items.add(item);
      await _saveToWeb(items);
      return 1;
    }

    final db = await database;
    return await db.insert(
      'shopping_items',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 여러 구매 목록 아이템 일괄 추가
  Future<void> insertShoppingItems(List<ShoppingItem> newItems) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      items.addAll(newItems);
      await _saveToWeb(items);
      return;
    }

    final db = await database;
    final batch = db.batch();

    for (final item in newItems) {
      batch.insert(
        'shopping_items',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // 모든 구매 목록 조회
  Future<List<ShoppingItem>> getAllShoppingItems() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 완료되지 않은 구매 목록 조회
  Future<List<ShoppingItem>> getPendingShoppingItems() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final pending = items.where((item) => !item.isCompleted).toList();
      pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pending;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 완료된 구매 목록 조회
  Future<List<ShoppingItem>> getCompletedShoppingItems() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final completed = items.where((item) => item.isCompleted).toList();
      completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return completed;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 기간별 구매 목록 조회
  Future<List<ShoppingItem>> getShoppingItemsByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final filtered =
          items
              .where(
                (item) =>
                    item.createdAt.isAfter(startDate) &&
                    item.createdAt.isBefore(endDate),
              )
              .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'createdAt >= ? AND createdAt <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 오늘 구매 목록 조회
  Future<List<ShoppingItem>> getTodayShoppingItems() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getShoppingItemsByPeriod(startOfDay, endOfDay);
  }

  // 이번 주 구매 목록 조회
  Future<List<ShoppingItem>> getThisWeekShoppingItems() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfWeek = startOfWeekDay.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return await getShoppingItemsByPeriod(startOfWeekDay, endOfWeek);
  }

  // 이번 달 구매 목록 조회
  Future<List<ShoppingItem>> getThisMonthShoppingItems() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await getShoppingItemsByPeriod(startOfMonth, endOfMonth);
  }

  // 올해 구매 목록 조회
  Future<List<ShoppingItem>> getThisYearShoppingItems() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return await getShoppingItemsByPeriod(startOfYear, endOfYear);
  }

  // 구매 목록 아이템 업데이트
  Future<int> updateShoppingItem(ShoppingItem item) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final index = items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        items[index] = item;
        await _saveToWeb(items);
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'shopping_items',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // 구매 목록 아이템 완료 상태 토글
  Future<int> toggleShoppingItemComplete(String itemId) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final index = items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        items[index] = items[index].copyWith(
          isCompleted: !items[index].isCompleted,
        );
        await _saveToWeb(items);
        return 1;
      }
      return 0;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (maps.isNotEmpty) {
      final item = ShoppingItem.fromJson(maps.first);
      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);

      return await db.update(
        'shopping_items',
        updatedItem.toJson(),
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }

    return 0;
  }

  // 구매 목록 아이템 삭제
  Future<int> deleteShoppingItem(String itemId) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final initialLength = items.length;
      items.removeWhere((item) => item.id == itemId);
      await _saveToWeb(items);
      return initialLength - items.length;
    }

    final db = await database;
    return await db.delete(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // 완료된 구매 목록 일괄 삭제
  Future<int> deleteCompletedItems() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final initialLength = items.length;
      items.removeWhere((item) => item.isCompleted);
      await _saveToWeb(items);
      return initialLength - items.length;
    }

    final db = await database;
    return await db.delete(
      'shopping_items',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
  }

  // 모든 구매 목록 삭제
  Future<int> deleteAllShoppingItems() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final count = items.length;
      await _saveToWeb([]);
      return count;
    }

    final db = await database;
    return await db.delete('shopping_items');
  }

  // 검색 기능
  Future<List<ShoppingItem>> searchShoppingItems(String query) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final filtered =
          items
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    (item.notes?.toLowerCase().contains(query.toLowerCase()) ??
                        false) ||
                    (item.category?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'name LIKE ? OR notes LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 카테고리별 구매 목록 조회
  Future<List<ShoppingItem>> getShoppingItemsByCategory(String category) async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final filtered =
          items.where((item) => item.category == category).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_items',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ShoppingItem.fromJson(maps[i]);
    });
  }

  // 모든 카테고리 조회
  Future<List<String>> getAllCategories() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      final categories =
          items
              .where((item) => item.category != null)
              .map((item) => item.category!)
              .toSet()
              .toList();
      categories.sort();
      return categories;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM shopping_items WHERE category IS NOT NULL ORDER BY category',
    );

    return maps.map((map) => map['category'] as String).toList();
  }

  // 통계 정보 조회
  Future<Map<String, int>> getStatistics() async {
    if (kIsWeb) {
      final items = await _loadFromWeb();
      return {
        'total': items.length,
        'completed': items.where((item) => item.isCompleted).length,
        'pending': items.where((item) => !item.isCompleted).length,
      };
    }

    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_items',
    );
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_items WHERE isCompleted = 1',
    );
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_items WHERE isCompleted = 0',
    );

    return {
      'total': totalResult.first['count'] as int,
      'completed': completedResult.first['count'] as int,
      'pending': pendingResult.first['count'] as int,
    };
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    if (!kIsWeb) {
      final db = await database;
      await db.close();
    }
  }
}
