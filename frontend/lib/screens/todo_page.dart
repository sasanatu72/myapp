import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTodos);
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todos = await context.read<TodoService>().getTodos();
      setState(() {
        _todos = todos;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Todo追加'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'タイトル',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('追加'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (controller.text.trim().isEmpty) return;

    try {
      await context.read<TodoService>().createTodo(
            title: controller.text.trim(),
          );
      await _loadTodos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_todos.isEmpty) {
      return const Center(child: Text('Todoはまだありません'));
    }

    return ListView.builder(
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return CheckboxListTile(
          value: todo.isDone,
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: todo.dueDate != null
              ? Text('期限: ${todo.dueDate!.toLocal()}'.split(' ')[0])
              : null,
          onChanged: (value) async {
            try {
              await context.read<TodoService>().updateTodo(
                    id: todo.id,
                    isDone: value ?? false,
                  );
              await _loadTodos();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              try {
                await context.read<TodoService>().deleteTodo(todo.id);
                await _loadTodos();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}