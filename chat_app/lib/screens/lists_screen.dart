import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_list.dart';
import '../services/list_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'list_detail_screen.dart';

/// Screen displaying all task lists in a grid layout.
class ListsScreen extends StatefulWidget {
  final bool autoAdd;

  const ListsScreen({super.key, this.autoAdd = false});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _listService = ListService();

  List<TaskList> _lists = [];
  bool _isLoading = true;

  static const List<String> _emojiOptions = [
    '📝', '🛒', '💡', '📚', '🏋️', '🎯', '🏠', '💼',
    '🎵', '🍳', '✈️', '🎮', '❤️', '🎨', '📱', '🌱',
  ];

  @override
  void initState() {
    super.initState();
    _loadLists();
    if (widget.autoAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddDialog());
    }
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    final lists = await _listService.getAll();
    if (mounted) {
      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    String selectedEmoji = '📝';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      'New List',
                      style: AppTheme.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'List name',
                        hintText: 'Shopping, To-Do, Ideas...',
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Choose an icon',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Wrap(
                      spacing: AppTheme.spacingS,
                      runSpacing: AppTheme.spacingS,
                      children: _emojiOptions.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.05),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child:
                                  Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Create List'),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _listService.addList(
        name: nameController.text.trim(),
        emoji: selectedEmoji,
      );
      _loadLists();
    }

    nameController.dispose();
  }

  Future<void> _deleteList(TaskList taskList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
            'Delete "${taskList.name}" and all its items?'),
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
      await _listService.deleteList(taskList.id);
      _loadLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lists',
          style: AppTheme.headingSmall
              .copyWith(color: theme.colorScheme.onSurface),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadLists,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppTheme.spacingM,
                      crossAxisSpacing: AppTheme.spacingM,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _lists.length,
                    itemBuilder: (context, index) {
                      final list = _lists[index];
                      return _ListCard(
                        taskList: list,
                        onTap: () async {
                          HapticService.instance.lightImpact();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListDetailScreen(listId: list.id),
                            ),
                          );
                          _loadLists();
                        },
                        onDelete: () => _deleteList(list),
                      )
                          .animate()
                          .fadeIn(
                            duration: AppConstants.animationNormal,
                            delay: Duration(milliseconds: index * 60),
                          )
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1, 1),
                          );
                    },
                  ),
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
                color: AppTheme.secondaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist,
                size: 64,
                color: AppTheme.secondaryLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No lists yet',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Organize your tasks, shopping, and ideas.\nTap + to create your first list.',
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
}

class _ListCard extends StatelessWidget {
  final TaskList taskList;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ListCard({
    required this.taskList,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(taskList.emoji, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  if (taskList.totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '${taskList.completedItems}/${taskList.totalItems}',
                        style: AppTheme.caption.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                taskList.name,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              if (taskList.totalItems > 0) ...[
                Text(
                  '${taskList.pendingItems} remaining',
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: taskList.completionPercentage,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    minHeight: 4,
                  ),
                ),
              ] else
                Text(
                  'No items yet',
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
