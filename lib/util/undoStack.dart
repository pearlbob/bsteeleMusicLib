//
//
///  An undo stack utility that assumes the contents are immutable.
class UndoStack<T> {
  UndoStack() : _max = _defaultSize;

  UndoStack.forMax(int m) : _max = m <= 0 ? _defaultSize : m;

  /// push data on to the undo stack
  void push(T value) {
    //  remove the dead edits in the redo top
    if (canRedo) {
      while (_undoStack.isNotEmpty && _undoStack.length > _undoStackPointer + 1) {
        _undoStack.remove(_undoStack.length - 1);
      }
    }

    //  cut the maxed out undo's off the stack
    if (_undoStackPointer >= _max - 1) _undoStack.remove(0);

    //  store the value in the undo stack

    _undoStack.add(value);

    _undoStackPointer = _undoStack.length - 1;
    _undoStackCount = _undoStackPointer;
  }

  /// see if there is data that can be undone
  bool get canUndo => _undoStackPointer > 0;

  /// pop the current value off the stack, i.e. undo
  T pop() {
    if (!canUndo) return null;
    T ret = top;
    _undoStackPointer--;
    return ret;
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

  /// get the top of the undo stack
  T get top => _undoStack[_undoStackPointer];


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
