class ToastModel {
  final String id;
  final String icon;
  final String title;
  final String message;
  final Duration duration;

  const ToastModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.message,
    this.duration = const Duration(seconds: 6),
  });
}
