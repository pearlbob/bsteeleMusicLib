class UsTimer {
  /// Microseconds since last reset, construction or measurement
  int get us {
    int us = DateTime.now().microsecondsSinceEpoch;
    _lastEpochUs = us;
    return us - _initialEpochUs;
  }

  /// Seconds since construction
  double get seconds => (DateTime.now().microsecondsSinceEpoch - _initialEpochUs) / Duration.microsecondsPerSecond;

  /// Microseconds since construction or last call
  int get deltaUs {
    int us = DateTime.now().microsecondsSinceEpoch;
    int lastUs = _lastEpochUs ?? _initialEpochUs;
    _lastEpochUs = us;
    return us - lastUs;
  }

  void reset() {
    _lastEpochUs = DateTime.now().microsecondsSinceEpoch;
  }

  String deltaToString() {
    return '${(deltaUs.toDouble() / Duration.microsecondsPerMillisecond).toStringAsFixed(3)} ms';
  }

  @override
  String toString() {
    return '${(us.toDouble() / Duration.microsecondsPerMillisecond).toStringAsFixed(3)} ms';
  }

  final int _initialEpochUs = DateTime.now().microsecondsSinceEpoch;
  int? _lastEpochUs;
}
