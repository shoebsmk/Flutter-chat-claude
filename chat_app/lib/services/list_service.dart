import '../models/task_list.dart';
import 'local_storage_service.dart';

/// Service for CRUD operations on task lists and their items.
class ListService {
  static const String _storageKey = 'task_lists';

  Future<List<TaskList>> getAll() async {
    final data = await LocalStorageService.loadList(_storageKey);
    final lists = data.map((json) => TaskList.fromJson(json)).toList();
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lists;
  }

  Future<TaskList?> getById(String id) async {
    final lists = await getAll();
    final matches = lists.where((l) => l.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<TaskList> addList({
    required String name,
    String emoji = '📝',
  }) async {
    final lists = await getAll();
    final taskList = TaskList.create(name: name, emoji: emoji);
    lists.insert(0, taskList);
    await _save(lists);
    return taskList;
  }

  Future<void> updateList(TaskList taskList) async {
    final lists = await getAll();
    final index = lists.indexWhere((l) => l.id == taskList.id);
    if (index != -1) {
      lists[index] = taskList;
      await _save(lists);
    }
  }

  Future<void> deleteList(String id) async {
    final lists = await getAll();
    lists.removeWhere((l) => l.id == id);
    await _save(lists);
  }

  Future<void> addItem(String listId, String content) async {
    final lists = await getAll();
    final index = lists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = lists[index];
      final item = TaskItem.create(
        content: content,
        position: list.items.length,
      );
      final updatedItems = [...list.items, item];
      lists[index] = list.copyWith(items: updatedItems);
      await _save(lists);
    }
  }

  Future<void> toggleItem(String listId, String itemId) async {
    final lists = await getAll();
    final listIndex = lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isCompleted: !item.isCompleted);
        }
        return item;
      }).toList();
      lists[listIndex] = list.copyWith(items: updatedItems);
      await _save(lists);
    }
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final lists = await getAll();
    final listIndex = lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = lists[listIndex];
      final updatedItems =
          list.items.where((item) => item.id != itemId).toList();
      lists[listIndex] = list.copyWith(items: updatedItems);
      await _save(lists);
    }
  }

  Future<void> updateItem(
    String listId,
    String itemId,
    String newContent,
  ) async {
    final lists = await getAll();
    final listIndex = lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = lists[listIndex];
      final updatedItems = list.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(content: newContent);
        }
        return item;
      }).toList();
      lists[listIndex] = list.copyWith(items: updatedItems);
      await _save(lists);
    }
  }

  Future<int> getTotalPendingItems() async {
    final lists = await getAll();
    int count = 0;
    for (final list in lists) {
      count += list.pendingItems;
    }
    return count;
  }

  Future<void> _save(List<TaskList> lists) async {
    final data = lists.map((l) => l.toJson()).toList();
    await LocalStorageService.saveList(_storageKey, data);
  }
}
