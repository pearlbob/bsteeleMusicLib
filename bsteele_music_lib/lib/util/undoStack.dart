//
//
///  An undo stack utility that assumes the contents are immutable.
class UndoStack<T> {
  UndoStack() : _max = _defaultSize;

  UndoStack.withMax(int m) : _max = m <= 0 ? _defaultSize : m;

  /// push data on to the undo stack
  void push(T value) {
    //  remove the dead edits in the redo top
    if (canRedo) {
      while (_undoStack.isNotEmpty && _undoStack.length > _undoStackPointer ) {
        _undoStack.removeAt(_undoStack.length - 1);
      }
    }

    //  cut the maxed out undo's off the stack
    if (_undoStackPointer >= _max - 1) {
      _undoStack.removeAt(0);
    }

    //  store the value in the undo stack
    _undoStack.add(value);

    _undoStackPointer = _undoStack.length - 1;
    _undoStackCount = _undoStackPointer;
  }

  /// see if there is data that can be undone
  bool get canUndo => _undoStackPointer > 1 || (_undoStackPointer == 1 && _undoStack[0] != null);

  /// pop the current value off the stack, i.e. undo
  T undo() {
    if (!canUndo) return null;
    _undoStackPointer--;
    return top;
  }

  /// if there is data above the current pointer in the stack, a redo is possible
  bool get canRedo => _undoStackPointer < _undoStackCount;

  ///  return the data above the current level if there is an undo that can be redone
  T redo() {
    if (!canRedo) {
      return null;
    }
    _undoStackPointer++;
    return top;
  }

  int get length => _undoStack.length;
  int get pointer => _undoStackPointer;

  /// get the top of the undo stack
  T get top => _undoStackPointer >= 0 ? _undoStack[_undoStackPointer] : null;

  ///  return from down the stack, starting from zero
  T get(int i) {
    int index = _undoStackCount - i;
    if (index < 0 || index > _max - 1) return null;
    return _undoStack[index];
  }

  @override
  String toString() {
    return 'undoStack pointer: $_undoStackPointer,  count: $_undoStackCount';
  }

  final int _max;
  static final int _defaultSize = 100;
  final List<T> _undoStack = <T>[null];
  int _undoStackPointer = 0;
  int _undoStackCount = 0;
}
