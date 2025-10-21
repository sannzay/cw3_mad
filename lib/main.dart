import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskApp());
}

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };
  int get weight => switch (this) {
        Priority.low => 0,
        Priority.medium => 1,
        Priority.high => 2,
      };
}

class Task {
  String name;
  bool isDone;
  Priority priority;

  Task({required this.name, this.isDone = false, this.priority = Priority.medium});

  Map<String, dynamic> toMap() => {
        'name': name,
        'isDone': isDone,
        'priority': priority.name,
      };
  factory Task.fromMap(Map<String, dynamic> map) => Task(
        name: map['name'] as String,
        isDone: (map['isDone'] as bool?) ?? false,
        priority: Priority.values.firstWhere(
          (p) => p.name == (map['priority'] as String? ?? 'medium'),
          orElse: () => Priority.medium,
        ),
      );
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = [];
  Priority _selectedPriority = Priority.medium;

  static const _prefsKeyTasks = 'tasks_json_list';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKeyTasks) ?? [];
    final loaded = jsonList
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .map(Task.fromMap)
        .toList();
    setState(() {
      _tasks
        ..clear()
        ..addAll(loaded);
      _sortTasks();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList(_prefsKeyTasks, jsonList);
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(Task(name: text, priority: _selectedPriority));
      _sortTasks();
    });
    _controller.clear();
    _saveTasks();
  }

  void _toggleDone(int index, bool? value) {
    setState(() {
      _tasks[index].isDone = value ?? false;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _changePriority(int index, Priority newPriority) {
    setState(() {
      _tasks[index].priority = newPriority;
      _sortTasks();
    });
    _saveTasks();
  }

  void _sortTasks() {
    _tasks.sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Task name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<Priority>(
                  value: _selectedPriority,
                  onChanged: (p) => setState(() => _selectedPriority = p ?? Priority.medium),
                  items: const [
                    DropdownMenuItem(value: Priority.low, child: Text('Low')),
                    DropdownMenuItem(value: Priority.medium, child: Text('Medium')),
                    DropdownMenuItem(value: Priority.high, child: Text('High')),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _addTask, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('No tasks yet.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isDone,
                              onChanged: (v) => _toggleDone(index, v),
                            ),
                            title: Text(
                              task.name,
                              style: TextStyle(
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: Text('Priority: ${task.priority.label}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<Priority>(
                                  value: task.priority,
                                  onChanged: (p) {
                                    if (p != null) _changePriority(index, p);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: Priority.low, child: Text('Low')),
                                    DropdownMenuItem(value: Priority.medium, child: Text('Medium')),
                                    DropdownMenuItem(value: Priority.high, child: Text('High')),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteTask(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(_sortTasks),
        label: const Text('Sort by priority'),
        icon: const Icon(Icons.sort),
      ),
    );
  }
}