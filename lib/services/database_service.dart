import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class DatabaseService {
  static const String _baseUrl =
      'https://todorestfb-default-rtdb.firebaseio.com';

  Future<List<Task>> fetchTasks(String userId, String idToken) async {
    final url = Uri.parse(
        '$_baseUrl/tasks/$userId.json?auth=$idToken');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return [];

      final List<Task> tasks = [];
      final Map<String, dynamic> tasksMap =
          Map<String, dynamic>.from(data as Map);
      tasksMap.forEach((key, value) {
        final taskData = Map<String, dynamic>.from(value as Map);
        tasks.add(Task.fromJson(taskData));
      });

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to fetch tasks: ${response.statusCode}');
    }
  }

  Future<Task> addTask(Task task, String idToken) async {
    final url = Uri.parse(
        '$_baseUrl/tasks/${task.userId}/${task.id}.json?auth=$idToken');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200) {
      return task;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to add task: ${response.statusCode}');
    }
  }

  Future<Task> updateTask(Task task, String idToken) async {
    final url = Uri.parse(
        '$_baseUrl/tasks/${task.userId}/${task.id}.json?auth=$idToken');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200) {
      return task;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  Future<void> deleteTask(String userId, String taskId, String idToken) async {
    final url = Uri.parse(
        '$_baseUrl/tasks/$userId/$taskId.json?auth=$idToken');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }

  Future<void> toggleTaskCompletion(
      String userId, String taskId, bool isCompleted, String idToken) async {
    final url = Uri.parse(
        '$_baseUrl/tasks/$userId/$taskId.json?auth=$idToken');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'isCompleted': isCompleted}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired');
      }
      throw Exception('Failed to toggle task: ${response.statusCode}');
    }
  }

  /// Deletes all tasks for the given user by removing the user node.
  ///
  /// This simply sends a DELETE request to the user-level endpoint and does
  /// not return any value. Errors are thrown for non‑200 responses just like
  /// other methods in this service.
  Future<void> deleteAllTasks(String userId, String idToken) async {
    final url = Uri.parse('$_baseUrl/tasks/$userId.json?auth=$idToken');

    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to delete all tasks: ${response.statusCode}');
    }
  }
}
