import 'web_theme_color_stub.dart'
    if (dart.library.html) 'web_theme_color_web.dart' as impl;

void setWebThemeColor(String color) {
  impl.setWebThemeColor(color);
}