import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Task {
  String title;
  DateTime? dueDate;
  bool isCompleted;

  Task({required this.title, this.dueDate, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      dueDate:
          json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      setState(() {
        tasks.clear();
        tasks.addAll(tasksJson.map((e) => Task.fromJson(jsonDecode(e))));
      });
    }
  }

  void _addTask(BuildContext context) {
    String title = "";
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Task title"),
                onChanged: (val) {
                  title = val;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime now = DateTime.now();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                child: const Text("Pick due date"),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  setState(() {
                    tasks.add(Task(title: title, dueDate: selectedDate));
                  });
                  _saveTasks();
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Widget buildTaskTile(Task task, int index) {
    return Dismissible(
      key: Key(task.title + index.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Task"),
            content: Text("Are you sure you want to delete '${task.title}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        setState(() {
          tasks.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${task.title} deleted")),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: task.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text("Due: ${task.dueDate.toString().split(' ')[0]}")
            : const Text("No due date"),
        onTap: () {
          setState(() {
            task.isCompleted = !task.isCompleted;
          });
        },
        onLongPress: () {
          TextEditingController editController =
              TextEditingController(text: task.title);
          DateTime? selectedDate = task.dueDate;

          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text("Edit Task"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: editController,
                        decoration:
                            const InputDecoration(hintText: "Enter new title"),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate != null
                                  ? "Due: ${selectedDate.toString().split(' ')[0]}"
                                  : "No due date",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: const Text("Change"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          task.title = editController.text;
                          task.dueDate = selectedDate;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text("Save"),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildTaskList(String filter) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    List<Task> filtered = tasks.where((task) {
      if (filter == "all") return true;
      if (filter == "today") {
        return task.dueDate != null &&
            task.dueDate!.year == today.year &&
            task.dueDate!.month == today.month &&
            task.dueDate!.day == today.day &&
            !task.isCompleted;
      }
      if (filter == "tomorrow") {
        return task.dueDate != null &&
            task.dueDate!.year == tomorrow.year &&
            task.dueDate!.month == tomorrow.month &&
            task.dueDate!.day == tomorrow.day &&
            !task.isCompleted;
      }
      if (filter == "upcoming") {
        return task.dueDate != null &&
            task.dueDate!.isAfter(tomorrow) &&
            !task.isCompleted;
      }
      if (filter == "overdue") {
        return task.dueDate != null &&
            task.dueDate!.isBefore(today) &&
            !task.isCompleted;
      }
      if (filter == "completed") return task.isCompleted;
      return true;
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final task = filtered[index];
        return buildTaskTile(task, tasks.indexOf(task));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Task Manager"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "All"),
              Tab(text: "Today"),
              Tab(text: "Tomorrow"),
              Tab(text: "Upcoming"),
              Tab(text: "Overdue"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildTaskList("all"),
            buildTaskList("today"),
            buildTaskList("tomorrow"),
            buildTaskList("upcoming"),
            buildTaskList("overdue"),
            buildTaskList("completed"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addTask(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}