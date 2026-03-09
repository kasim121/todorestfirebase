import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

enum TaskStatus { initial, loading, loaded, error }

enum TaskFilter { all, active, completed }

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Task> _tasks = [];
  TaskStatus _status = TaskStatus.initial;
  String? _errorMessage;
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';

  List<Task> get tasks => _filteredTasks;
  List<Task> get allTasks => _tasks;
  TaskStatus get status => _status;
  String? get errorMessage => _errorMessage;
  TaskFilter get filter => _filter;
  String get searchQuery => _searchQuery;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get activeCount => _tasks.where((t) => !t.isCompleted).length;

  List<Task> get _filteredTasks {
    List<Task> result = _tasks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((task) {
        return task.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            task.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    return result;
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchTasks(String userId, String idToken) async {
    _status = TaskStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _dbService.fetchTasks(userId, idToken);
      _status = TaskStatus.loaded;
    } catch (e) {
      _status = TaskStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  Future<bool> addTask(Task task, String idToken) async {
    try {
      final newTask = await _dbService.addTask(task, idToken);
      _tasks.insert(0, newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task, String idToken) async {
    try {
      final updatedTask = await _dbService.updateTask(task, idToken);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(
      String userId, String taskId, String idToken) async {
    try {
      await _dbService.deleteTask(userId, taskId, idToken);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTaskCompletion(
      Task task, String idToken) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final index = _tasks.indexWhere((t) => t.id == task.id);

    // Optimistic update
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners();
    }

    try {
      await _dbService.toggleTaskCompletion(
          task.userId, task.id, !task.isCompleted, idToken);
      return true;
    } catch (e) {
      // Revert on failure
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearTasks() {
    _tasks = [];
    _status = TaskStatus.initial;
    _filter = TaskFilter.all;
    _searchQuery = '';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
