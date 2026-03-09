import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class DatabaseService {
  // Replace with your Firebase project URL
  static const String _baseUrl =
      'https://todorestfb-default-rtdb.firebaseio.com';

  /// Fetches all tasks for a user from Firebase Realtime Database via REST API
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

      // Sort by createdAt descending
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token expired');
    } else {
      throw Exception('Failed to fetch tasks: ${response.statusCode}');
    }
  }

  /// Adds a new task to Firebase Realtime Database via REST API (PUT with custom ID)
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

  /// Updates an existing task in Firebase Realtime Database via REST API
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

  /// Deletes a task from Firebase Realtime Database via REST API
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

  /// Toggles the completion status of a task
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
}
