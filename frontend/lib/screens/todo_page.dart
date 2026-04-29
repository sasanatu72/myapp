import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_page_container.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todos = await context.read<TodoService>().getTodos();

      if (!mounted) return;

      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    DateTime? dueDate;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('タスク追加'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'タイトル',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('期限'),
                          subtitle: Text(
                            dueDate == null ? '未設定' : formatDate(dueDate!),
                          ),
                          trailing: dueDate == null
                              ? const Icon(Icons.chevron_right)
                              : IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      dueDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                dueDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('追加'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != true) return;
      if (controller.text.trim().isEmpty) return;

      try {
        await context.read<TodoService>().createTodo(
              title: controller.text.trim(),
              dueDate: dueDate,
            );
        await _loadTodos();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク'),
      ),
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
      return AppPageContainer(
        child: ErrorState(
          message: _errorMessage!,
          onRetry: _loadTodos,
        ),
      );
    }

    if (_todos.isEmpty) {
      return AppPageContainer(
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'タスクはまだありません',
          message: '右下の＋ボタンから、新しいタスクを追加できます。',
          actionLabel: 'タスクを追加',
          onAction: _showCreateDialog,
        ),
      );
    }

    final sortedTodos = [..._todos]..sort((a, b) {
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.id.compareTo(b.id);
      });

    final remainingCount = _todos.where((todo) => !todo.isDone).length;
    final completedCount = _todos.where((todo) => todo.isDone).length;

    return AppPageContainer(
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt),
              title: Text('未完了 $remainingCount件'),
              subtitle: Text('完了済み $completedCount件'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: sortedTodos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final todo = sortedTodos[index];
                return _TodoCard(
                  todo: todo,
                  onChanged: (value) => _toggleTodo(todo, value ?? false),
                  onDelete: () => _deleteTodo(todo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodo(Todo todo, bool isDone) async {
    try {
      await context.read<TodoService>().updateTodo(
            id: todo.id,
            isDone: isDone,
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
  }

  Future<void> _deleteTodo(Todo todo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('タスクを削除しますか？'),
          content: Text('「${todo.title}」を削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

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
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onChanged,
    required this.onDelete,
  });

  final Todo todo;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: CheckboxListTile(
        value: todo.isDone,
        onChanged: onChanged,
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
        subtitle: todo.dueDate != null
            ? Text('期限: ${formatDate(todo.dueDate!)}')
            : const Text('期限なし'),
      ),
    );
  }
}