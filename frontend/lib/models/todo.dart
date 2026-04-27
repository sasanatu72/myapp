class Todo {
  final int id;
  final String title;
  final bool isDone;
  final DateTime? dueDate;

  Todo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.dueDate,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String,
      isDone: json['is_done'] as bool,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }
}
