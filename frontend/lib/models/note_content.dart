import 'dart:convert';

/// Versioned rich text in the existing TEXT column. Legacy notes stay plain text.
class NoteContent {
  const NoteContent({required this.text, this.html});

  final String text;
  final String? html;
  bool get isRichText => html != null;

  factory NoteContent.decode(String value) {
    try {
      final data = jsonDecode(value);
      if (data is Map<String, dynamic> &&
          data['lifeCustomDocument'] == 1 &&
          data['html'] is String &&
          data['text'] is String) {
        return NoteContent(
          text: data['text'] as String,
          html: data['html'] as String,
        );
      }
    } on FormatException {
      // Plain text is the original storage format, including literal HTML.
    }
    return NoteContent(text: value);
  }

  String encode() => html == null
      ? text
      : jsonEncode({'lifeCustomDocument': 1, 'html': html, 'text': text});
}
