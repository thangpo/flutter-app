import 'dart:async';
import 'dart:ui';

class DebounceHelper {
  final int milliseconds;
  Timer? _timer;

  DebounceHelper({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
