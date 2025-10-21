import 'package:flutter/material.dart';

void main() {
  runApp(const TaskApp());
}

class Task {
  String name;
  bool isDone;
  Task({required this.name, this.isDone = false});
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

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(Task(name: text));
    });
    _controller.clear();
  }

  void _toggleDone(int index, bool? value) {
    setState(() {
      _tasks[index].isDone = value ?? false;
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteTask(index),
                              tooltip: 'Delete',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}