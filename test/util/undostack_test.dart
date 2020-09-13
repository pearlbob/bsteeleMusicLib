import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/util/undoStack.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';


void main() {
  Logger.level = Level.info;

  test('test undo stack', () {

    UndoStack<String> undoStack = UndoStack();
    expect(undoStack.canUndo, false);

    undoStack.push('1');
    expect(undoStack.canUndo, false);
    undoStack.push('2');
    expect(undoStack.canUndo, true);
    undoStack.push('3');
    expect(undoStack.canUndo, true);
    undoStack.push('4');
    expect(undoStack.canUndo, true);
    expect(undoStack.top, '4');

    //  take a look
    for ( int i = 0; ; i++){
      String s = undoStack.get(i);
      if ( s == null ) {
        break;
      }
      logger.v('$i: "$s"');
      expect( s , (4 - i ).toString());
    }

    expect(undoStack.top, '4');
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '3');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '2');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '1');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);
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
    expect(undoStack.top, '4');
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    expect(undoStack.redo(), null);
  });
}
