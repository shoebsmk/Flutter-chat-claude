import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_list.dart';
import '../services/list_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Screen showing the items within a single task list.
class ListDetailScreen extends StatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _listService = ListService();
  final _addItemController = TextEditingController();
  final _addItemFocus = FocusNode();

  TaskList? _taskList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  @override
  void dispose() {
    _addItemController.dispose();
    _addItemFocus.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() => _isLoading = true);
    final list = await _listService.getById(widget.listId);
    if (mounted) {
      setState(() {
        _taskList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _addItem() async {
    final content = _addItemController.text.trim();
    if (content.isEmpty) return;

    await _listService.addItem(widget.listId, content);
    _addItemController.clear();
    _addItemFocus.requestFocus();
    _loadList();
  }

  Future<void> _toggleItem(String itemId) async {
    HapticService.instance.lightImpact();
    await _listService.toggleItem(widget.listId, itemId);
    _loadList();
  }

  Future<void> _deleteItem(String itemId) async {
    await _listService.deleteItem(widget.listId, itemId);
    _loadList();
  }

  Future<void> _editListName() async {
    if (_taskList == null) return;
    final controller = TextEditingController(text: _taskList!.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'List name'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _listService.updateList(_taskList!.copyWith(name: result));
      _loadList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_taskList == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('List not found')),
      );
    }

    final list = _taskList!;
    // Sort: uncompleted first, then completed
    final sortedItems = List<TaskItem>.from(list.items)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.position.compareTo(b.position);
      });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _editListName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(list.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.spacingS),
              Flexible(
                child: Text(
                  list.name,
                  style: AppTheme.headingSmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (list.totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingM),
              child: Center(
                child: Text(
                  '${list.completedItems}/${list.totalItems}',
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          if (list.totalItems > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: list.completionPercentage,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  minHeight: 6,
                ),
              ),
            ),

          // Items list
          Expanded(
            child: sortedItems.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                    itemCount: sortedItems.length,
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      return _TaskItemTile(
                        item: item,
                        onToggle: () => _toggleItem(item.id),
                        onDelete: () => _deleteItem(item.id),
                      )
                          .animate()
                          .fadeIn(
                            duration: AppConstants.animationNormal,
                            delay: Duration(milliseconds: index * 30),
                          );
                    },
                  ),
          ),

          // Add item input
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addItemController,
                    focusNode: _addItemFocus,
                    decoration: const InputDecoration(
                      hintText: 'Add an item...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
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
            Icon(
              Icons.playlist_add,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No items yet',
              style: AppTheme.bodyLarge.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            Text(
              'Add your first item below',
              style: AppTheme.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItemTile extends StatelessWidget {
  final TaskItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: 0,
        ),
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: item.isCompleted
                    ? AppTheme.successLight
                    : theme.colorScheme.onSurface.withOpacity(0.3),
                width: 2,
              ),
              color: item.isCompleted ? AppTheme.successLight : Colors.transparent,
            ),
            child: item.isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          item.content,
          style: AppTheme.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(
              item.isCompleted ? 0.4 : 1.0,
            ),
            decoration:
                item.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        onTap: onToggle,
      ),
    );
  }
}
