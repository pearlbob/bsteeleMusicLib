class RollingAverage {
  RollingAverage(this._size) : _data = List(_size);

  void reset() {
    _rollSize = 0;
    _currentIndex = 0;
  }

  double roll(double d) {
    _data[_currentIndex++] = d;
    if ( _currentIndex >= _size ) {
      _currentIndex = 0;
    }
    if (_rollSize < _size) {
      _rollSize++;
    }
    double sum = 0;
    for (int i = 0; i < _rollSize; i++) {
      sum += _data[i];
    }
    return sum / _rollSize;
  }

  final List<double> _data;
  int _rollSize = 0;
  int _currentIndex = 0;
  final int _size;
}
