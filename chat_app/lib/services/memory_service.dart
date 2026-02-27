import '../models/memory.dart';
import 'local_storage_service.dart';

/// Service for CRUD operations on memories/notes.
class MemoryService {
  static const String _storageKey = 'memories';

  Future<List<Memory>> getAll() async {
    final data = await LocalStorageService.loadList(_storageKey);
    final memories = data.map((json) => Memory.fromJson(json)).toList();
    // Sort: pinned first, then by updatedAt descending
    memories.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return memories;
  }

  Future<Memory> add({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final memories = await getAll();
    final memory = Memory.create(
      title: title,
      content: content,
      tags: tags,
    );
    memories.insert(0, memory);
    await _save(memories);
    return memory;
  }

  Future<void> update(Memory memory) async {
    final memories = await getAll();
    final index = memories.indexWhere((m) => m.id == memory.id);
    if (index != -1) {
      memories[index] = memory;
      await _save(memories);
    }
  }

  Future<void> delete(String id) async {
    final memories = await getAll();
    memories.removeWhere((m) => m.id == id);
    await _save(memories);
  }

  Future<void> togglePin(String id) async {
    final memories = await getAll();
    final index = memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      memories[index] = memories[index].copyWith(
        isPinned: !memories[index].isPinned,
      );
      await _save(memories);
    }
  }

  Future<List<Memory>> search(String query) async {
    final memories = await getAll();
    final lowerQuery = query.toLowerCase();
    return memories.where((m) {
      return m.title.toLowerCase().contains(lowerQuery) ||
          m.content.toLowerCase().contains(lowerQuery) ||
          m.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  Future<void> _save(List<Memory> memories) async {
    final data = memories.map((m) => m.toJson()).toList();
    await LocalStorageService.saveList(_storageKey, data);
  }
}
