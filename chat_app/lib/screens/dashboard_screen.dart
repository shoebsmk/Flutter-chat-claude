import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/memory.dart';
import '../models/reminder.dart';
import '../models/task_list.dart';
import '../services/memory_service.dart';
import '../services/reminder_service.dart';
import '../services/list_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'main_screen.dart';
import 'memories_screen.dart';
import 'reminders_screen.dart';
import 'lists_screen.dart';
import 'settings_screen.dart';

/// Dashboard home screen showing an overview of memories, reminders, and lists.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _memoryService = MemoryService();
  final _reminderService = ReminderService();
  final _listService = ListService();
  final _authService = AuthService();

  List<Memory> _recentMemories = [];
  List<Reminder> _upcomingReminders = [];
  List<TaskList> _recentLists = [];
  int _overdueCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final memories = await _memoryService.getAll();
    final reminders = await _reminderService.getUpcoming();
    final lists = await _listService.getAll();
    final overdue = await _reminderService.getOverdueCount();

    if (mounted) {
      setState(() {
        _recentMemories = memories.take(3).toList();
        _upcomingReminders = reminders.take(3).toList();
        _recentLists = lists.take(3).toList();
        _overdueCount = overdue;
        _isLoading = false;
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: AppTheme.headingSmall.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                children: [
                  _buildGreeting(theme),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildQuickActions(theme),
                  const SizedBox(height: AppTheme.spacingL),
                  if (_overdueCount > 0) ...[
                    _buildOverdueAlert(theme),
                    const SizedBox(height: AppTheme.spacingM),
                  ],
                  _buildSection(
                    theme,
                    title: 'Upcoming Reminders',
                    icon: Icons.alarm,
                    onSeeAll: () => _navigateToTab(3),
                    child: _upcomingReminders.isEmpty
                        ? _buildEmptyHint(theme, 'No upcoming reminders')
                        : _buildRemindersList(theme),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildSection(
                    theme,
                    title: 'Recent Memories',
                    icon: Icons.lightbulb_outline,
                    onSeeAll: () => _navigateToTab(2),
                    child: _recentMemories.isEmpty
                        ? _buildEmptyHint(theme, 'No memories saved yet')
                        : _buildMemoriesList(theme),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildSection(
                    theme,
                    title: 'Your Lists',
                    icon: Icons.checklist,
                    onSeeAll: () => _navigateToTab(4),
                    child: _recentLists.isEmpty
                        ? _buildEmptyHint(theme, 'No lists created yet')
                        : _buildListsGrid(theme),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
      ),
    );
  }

  void _navigateToTab(int index) {
    final mainScreenState =
        context.findAncestorStateOfType<MainScreenState>();
    mainScreenState?.switchTab(index);
  }

  Widget _buildGreeting(ThemeData theme) {
    final email = _authService.currentUserEmail ?? '';
    final name = email.split('@').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting,',
          style: AppTheme.headingLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn(duration: AppConstants.animationSlow).slideX(
              begin: -0.1,
              end: 0,
            ),
        Text(
          name,
          style: AppTheme.headingMedium.copyWith(
            color: theme.colorScheme.primary,
          ),
        ).animate(delay: 100.ms).fadeIn(duration: AppConstants.animationSlow),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.lightbulb_outline,
            label: 'New Memory',
            color: theme.colorScheme.primary,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemoriesScreen(autoAdd: true)),
              );
              _loadData();
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.alarm_add,
            label: 'New Reminder',
            color: AppTheme.successLight,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen(autoAdd: true)),
              );
              _loadData();
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_task,
            label: 'New List',
            color: AppTheme.secondaryLight,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ListsScreen(autoAdd: true)),
              );
              _loadData();
            },
          ),
        ),
      ],
    ).animate().fadeIn(
          duration: AppConstants.animationSlow,
          delay: 200.ms,
        );
  }

  Widget _buildOverdueAlert(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              '$_overdueCount overdue reminder${_overdueCount > 1 ? 's' : ''}',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _navigateToTab(3),
            child: const Text('View'),
          ),
        ],
      ),
    ).animate().fadeIn().shake(delay: 500.ms, hz: 2, curve: Curves.easeInOut);
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required VoidCallback onSeeAll,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                title,
                style: AppTheme.headingSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        child,
      ],
    );
  }

  Widget _buildEmptyHint(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodyMedium.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildRemindersList(ThemeData theme) {
    return Column(
      children: _upcomingReminders.map((reminder) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: reminder.isOverdue
                ? Border.all(color: theme.colorScheme.error.withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: reminder.isOverdue
                      ? theme.colorScheme.error.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  reminder.isRecurring ? Icons.repeat : Icons.alarm,
                  color: reminder.isOverdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatReminderDate(reminder.dueDate),
                      style: AppTheme.caption.copyWith(
                        color: reminder.isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemoriesList(ThemeData theme) {
    return Column(
      children: _recentMemories.map((memory) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            children: [
              if (memory.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: Icon(Icons.push_pin,
                      size: 16, color: theme.colorScheme.primary),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      memory.content,
                      style: AppTheme.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (memory.tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                  ),
                  child: Text(
                    memory.tags.first,
                    style: AppTheme.caption.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListsGrid(ThemeData theme) {
    return Row(
      children: _recentLists.map((list) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: AppTheme.spacingS),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(list.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  list.name,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${list.completedItems}/${list.totalItems}',
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (list.totalItems > 0) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: list.completionPercentage,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) {
      if (diff.inDays == 0) return 'Overdue today';
      return 'Overdue by ${-diff.inDays} day${-diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
