import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/memory.dart';
import '../services/memory_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// Screen displaying all memories with search and add/edit functionality.
class MemoriesScreen extends StatefulWidget {
  final bool autoAdd;

  const MemoriesScreen({super.key, this.autoAdd = false});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _memoryService = MemoryService();
  final _searchController = TextEditingController();

  List<Memory> _memories = [];
  List<Memory> _filteredMemories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMemories();
    _searchController.addListener(_onSearchChanged);
    if (widget.autoAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddDialog());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _filterMemories();
      });
    }
  }

  void _filterMemories() {
    if (_searchQuery.isEmpty) {
      _filteredMemories = _memories;
    } else {
      _filteredMemories = _memories.where((m) {
        return m.title.toLowerCase().contains(_searchQuery) ||
            m.content.toLowerCase().contains(_searchQuery) ||
            m.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      }).toList();
    }
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    final memories = await _memoryService.getAll();
    if (mounted) {
      setState(() {
        _memories = memories;
        _filterMemories();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog([Memory? existing]) async {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final contentController =
        TextEditingController(text: existing?.content ?? '');
    final tagsController =
        TextEditingController(text: existing?.tags.join(', ') ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    existing != null ? 'Edit Memory' : 'New Memory',
                    style: AppTheme.headingSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What do you want to remember?',
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Add details...',
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma separated)',
                      hintText: 'work, personal, idea',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.of(context).pop(true);
                    },
                    child: Text(existing != null ? 'Update' : 'Save Memory'),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      final tags = tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (existing != null) {
        await _memoryService.update(existing.copyWith(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          tags: tags,
        ));
      } else {
        await _memoryService.add(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          tags: tags,
        );
      }
      _loadMemories();
    }

    titleController.dispose();
    contentController.dispose();
    tagsController.dispose();
  }

  Future<void> _deleteMemory(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory'),
        content: Text('Delete "${memory.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _memoryService.delete(memory.id);
      _loadMemories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Memories',
          style: AppTheme.headingSmall
              .copyWith(color: theme.colorScheme.onSurface),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMemories.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildMemoryList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              _searchQuery.isEmpty ? 'No memories yet' : 'No results found',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _searchQuery.isEmpty
                  ? 'Save thoughts, ideas, and important info.\nTap + to add your first memory.'
                  : 'Try a different search term.',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      itemCount: _filteredMemories.length,
      itemBuilder: (context, index) {
        final memory = _filteredMemories[index];
        return _MemoryCard(
          memory: memory,
          onTap: () => _showAddDialog(memory),
          onDelete: () => _deleteMemory(memory),
          onTogglePin: () async {
            HapticService.instance.lightImpact();
            await _memoryService.togglePin(memory.id);
            _loadMemories();
          },
        )
            .animate()
            .fadeIn(
              duration: AppConstants.animationNormal,
              delay: Duration(milliseconds: index * 40),
            )
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _MemoryCard({
    required this.memory,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(memory.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (memory.isPinned)
                      Padding(
                        padding:
                            const EdgeInsets.only(right: AppTheme.spacingXS),
                        child: Icon(Icons.push_pin,
                            size: 16, color: theme.colorScheme.primary),
                      ),
                    Expanded(
                      child: Text(
                        memory.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'pin') onTogglePin();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(
                              memory.isPinned ? 'Unpin' : 'Pin to top'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                if (memory.content.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    memory.content,
                    style: AppTheme.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    if (memory.tags.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          spacing: AppTheme.spacingXS,
                          children: memory.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXS),
                              ),
                              child: Text(
                                tag,
                                style: AppTheme.caption.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      AppDateUtils.formatRelative(memory.updatedAt),
                      style: AppTheme.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
