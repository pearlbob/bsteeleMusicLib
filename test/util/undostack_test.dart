import 'package:bsteeleMusicLib/util/undoStack.dart';
import 'package:test/test.dart';

void main() {
  test('test undo stack', () {

    UndoStack<String> undoStack = UndoStack();
    expect(undoStack.canUndo, false);

    undoStack.push('1');
    expect(undoStack.canUndo, true);
    undoStack.push('2');
    expect(undoStack.canUndo, true);
    undoStack.push('3');
    expect(undoStack.canUndo, true);
    undoStack.push('4');
    expect(undoStack.canUndo, true);
    expect(undoStack.top, '4');
    expect(undoStack.pop(), '4');
    expect(undoStack.canUndo, true);
    expect(undoStack.pop(), '3');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.pop(), '2');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.pop(), '1');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);
    expect(undoStack.canRedo, true);
    expect(undoStack.redo(), '1');
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, true);
    expect(undoStack.redo(), '2');
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, true);
    expect(undoStack.redo(), '3');
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, true);
    expect(undoStack.redo(), '4');
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    expect(undoStack.redo(), null);
  });
}
