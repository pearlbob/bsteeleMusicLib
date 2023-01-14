class UsTimer {
  /// Microseconds since construction
  int get us {
    int us = DateTime.now().microsecondsSinceEpoch;
    _lastEpochUs = us;
    return us - _initialEpochUs;
  }

  /// Seconds since construction
  double get seconds => (DateTime.now().microsecondsSinceEpoch - _initialEpochUs) / Duration.microsecondsPerSecond;

  /// Microseconds since construction or last call
  int get delta {
    int us = DateTime.now().microsecondsSinceEpoch;
    int lastUs = _lastEpochUs ?? _initialEpochUs;
    _lastEpochUs = us;
    return us - lastUs;
  }

  String deltaToString() {
    return '${(delta.toDouble() / Duration.microsecondsPerMillisecond).toStringAsFixed(3)} ms';
  }

  @override
  String toString() {
    return '${(us.toDouble() / Duration.microsecondsPerMillisecond).toStringAsFixed(3)} ms';
  }

  final int _initialEpochUs = DateTime.now().microsecondsSinceEpoch;
  int? _lastEpochUs;
}
