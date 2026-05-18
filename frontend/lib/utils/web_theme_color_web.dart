import 'dart:html' as html;

void setWebThemeColor(String color) {
  _setMeta('theme-color', color);

  // iOS Safari / PWA が背景色を拾う場合があるため、html/body側も合わせる
  html.document.documentElement?.style.backgroundColor = color;
  html.document.body?.style.backgroundColor = color;
}

void _setMeta(String name, String content) {
  final existing = html.document.head?.querySelector('meta[name="$name"]');

  if (existing is html.MetaElement) {
    existing.content = content;
    return;
  }

  final meta = html.MetaElement()
    ..name = name
    ..content = content;

  html.document.head?.append(meta);
}