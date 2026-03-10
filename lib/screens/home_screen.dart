import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskProvider>().setFilter(TaskFilter.all);
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final taskProvider = context.read<TaskProvider>();
        switch (_tabController.index) {
          case 0:
            taskProvider.setFilter(TaskFilter.all);
            break;
          case 1:
            taskProvider.setFilter(TaskFilter.active);
            break;
          case 2:
            taskProvider.setFilter(TaskFilter.completed);
            break;
        }
      }
    });
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final token = await authProvider.getIdToken();
    final userId = authProvider.user?.uid;
    if (token != null && userId != null) {
      await taskProvider.fetchTasks(userId, token);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTaskSheet(),
    );
  }

  void _openEditTaskSheet(task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskSheet(task: task),
    );
  }

  Future<bool> _confirmClearTasks(TaskFilter filter, int count) async {
    String label;
    switch (filter) {
      case TaskFilter.completed:
        label = 'completed';
        break;
      case TaskFilter.active:
        label = 'active';
        break;
      case TaskFilter.all:
        label = 'all';
        break;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Tasks'),
        content: Text('Delete $count $label task${count == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    return shouldClear ?? false;
  }

  Future<void> _clearTasksByFilter(TaskFilter filter) async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    final count = switch (filter) {
      TaskFilter.completed => taskProvider.completedCount,
      TaskFilter.active => taskProvider.activeCount,
      TaskFilter.all => taskProvider.totalCount,
    };

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to clear')),
      );
      return;
    }

    final shouldClear = await _confirmClearTasks(filter, count);
    if (!shouldClear || !mounted) return;

    final token = await authProvider.getIdToken();
    final userId = authProvider.user?.uid;

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to clear tasks right now'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final success = await taskProvider.deleteTasksByFilter(userId, token, filter);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tasks cleared successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(taskProvider.errorMessage ?? 'Failed to clear tasks'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<bool> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    return shouldSignOut ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = authProvider.user;
    final firstName = (user?.displayName ?? 'User').split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, firstName, authProvider),

            _buildStats(taskProvider),
            if (_showSearch) _buildSearchBar(taskProvider),
            _buildTabs(taskProvider),
            Expanded(
              child: _buildTaskList(taskProvider, authProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTaskSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, String firstName, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  "Let's check your tasks",
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => _showProfileMenu(context, authProvider),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: authProvider.user?.photoURL != null
                  ? NetworkImage(authProvider.user!.photoURL!)
                  : null,
              child: authProvider.user?.photoURL == null
                  ? Text(
                      firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              label: 'Total',
              value: taskProvider.totalCount,
              color: AppTheme.primaryColor,
              icon: Icons.list_alt_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              label: 'Active',
              value: taskProvider.activeCount,
              color: AppTheme.warningColor,
              icon: Icons.pending_actions_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              label: 'Done',
              value: taskProvider.completedCount,
              color: AppTheme.successColor,
              icon: Icons.task_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: taskProvider.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    taskProvider.setSearchQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTabs(TaskProvider taskProvider) {
    final selectedFilter = taskProvider.filter;
    final clearCount = switch (selectedFilter) {
      TaskFilter.completed => taskProvider.completedCount,
      TaskFilter.active => taskProvider.activeCount,
      TaskFilter.all => taskProvider.totalCount,
    };
    final canShowClearAction = switch (selectedFilter) {
      TaskFilter.all => clearCount > 1,
      TaskFilter.active => clearCount > 1,
      TaskFilter.completed => clearCount > 1,
    };
    final clearLabel = switch (selectedFilter) {
      TaskFilter.completed => 'Clear Completed',
      TaskFilter.active => 'Clear Active',
      TaskFilter.all => 'Clear All',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          if (canShowClearAction)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _clearTasksByFilter(selectedFilter),
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  size: 18,
                  color: AppTheme.errorColor,
                ),
                label: Text(
                  '$clearLabel ($clearCount)',
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider, AuthProvider authProvider) {
    if (taskProvider.status == TaskStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (taskProvider.status == TaskStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              taskProvider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tasks = taskProvider.tasks;

    if (tasks.isEmpty) {
      return _buildEmptyState(taskProvider);
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onTap: () {
              if (task.isCompleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completed tasks cannot be edited'),
                  ),
                );
                return;
              }
              _openEditTaskSheet(task);
            },
            onToggle: () async {
              final token = await authProvider.getIdToken();
              if (token != null) {
                await taskProvider.toggleTaskCompletion(task, token);
              }
            },
            onDelete: () async {
              final token = await authProvider.getIdToken();
              if (token != null) {
                final deleted = await taskProvider.deleteTask(
                    task.userId, task.id, token);
                if (deleted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted'),
                      backgroundColor: AppTheme.errorColor,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: Colors.white,
                        onPressed: () async {
                          final t2 = await authProvider.getIdToken();
                          if (t2 != null) {
                            await taskProvider.addTask(task, t2);
                          }
                        },
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(TaskProvider taskProvider) {
    final filter = taskProvider.filter;
    final searchQuery = taskProvider.searchQuery;

    String title;
    String subtitle;
    IconData icon;

    if (searchQuery.isNotEmpty) {
      title = 'No results found';
      subtitle = 'Try a different search term';
      icon = Icons.search_off_rounded;
    } else if (filter == TaskFilter.completed) {
      title = 'No completed tasks';
      subtitle = 'Finish some tasks and they\'ll appear here';
      icon = Icons.task_alt_rounded;
    } else if (filter == TaskFilter.active) {
      title = 'All tasks done!';
      subtitle = 'Great job! You completed everything 🎉';
      icon = Icons.celebration_rounded;
    } else {
      title = 'No tasks yet';
      subtitle = 'Tap the button below to add your first task';
      icon = Icons.add_task_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              leading: Consumer<ThemeProvider>(
                builder: (_, themeProvider, __) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.isDark
                        ? AppTheme.textSecondary.withAlpha(20)
                        : AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round_rounded,
                    color: themeProvider.isDark
                        ? AppTheme.textSecondary
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
              title: Consumer<ThemeProvider>(
                builder: (_, themeProvider, __) => Text(
                  themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDark
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary),
                ),
              ),
              onTap: () {
                context.read<ThemeProvider>().toggle();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.errorColor),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.errorColor),
              ),
              onTap: () async {
                Navigator.pop(context);
                final shouldSignOut = await _confirmSignOut();
                if (!shouldSignOut || !mounted) {
                  return;
                }
                context.read<TaskProvider>().clearTasks();
                await authProvider.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
