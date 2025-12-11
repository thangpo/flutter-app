/// Tạm chặn hiển thị dialog/ sheet thoát app (AppExitCard) trong một khoảng
/// thời gian ngắn khi có điều hướng kỹ thuật (vd: CallKit tự pop CallScreen).
class AppExitGuard {
  static DateTime? _until;

  /// Gọi khi muốn chặn 1 lần trong [duration].
  static void suppressFor(Duration duration) {
    _until = DateTime.now().add(duration);
  }

  /// true nếu đang trong thời gian chặn.
  static bool get isSuppressed {
    final u = _until;
    return u != null && DateTime.now().isBefore(u);
  }
}
