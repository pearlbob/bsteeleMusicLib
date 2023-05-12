import 'package:bsteele_music_lib/app_logger.dart';
import 'package:bsteele_music_lib/util/undo_stack.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void _logStack(UndoStack undoStack) {
  logger.i('$undoStack:');
}

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
    _logStack(undoStack);

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
    assert(undoStack.pointer == undoStack.length -1);
    expect(undoStack.undo(), '3');
    assert(undoStack.pointer < undoStack.length -1);


    undoStack.push('2+1');
    assert(undoStack.pointer == undoStack.length -1);
    undoStack.push('2+2');
    assert(undoStack.pointer == undoStack.length -1);
    _logStack(undoStack);
    expect(undoStack.top, '2+2');
    expect(undoStack.undo(), '2+1');
    assert(undoStack.pointer < undoStack.length -1);
    expect(undoStack.undo(), '2');
    assert(undoStack.pointer < undoStack.length -1);
    undoStack.push('1a');
    assert(undoStack.pointer == undoStack.length -1);
    undoStack.push('1b');
    assert(undoStack.pointer == undoStack.length -1);
    _logStack(undoStack);
    expect(undoStack.undo(), '1a');
    assert(undoStack.pointer < undoStack.length -1);
    expect(undoStack.undo(), '1');
    assert(undoStack.pointer < undoStack.length -1);
    expect(undoStack.canUndo, false );
    expect(undoStack.canRedo, true);
    expect(undoStack.undo(), '1');
    assert(undoStack.pointer < undoStack.length -1);
  });


  test('test undo stack after complete undo', () {

    UndoStack<String> undoStack = UndoStack();
    expect(undoStack.canUndo, false);
    expect(undoStack.canRedo, false);

    undoStack.push('0');
    _logStack(undoStack);
    expect(undoStack.canUndo, false);
    expect(undoStack.canRedo, false);
    undoStack.push('1');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    undoStack.push('2');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    undoStack.push('3');
    expect(undoStack.top, '3');

    //  take a look
    _logStack(undoStack);

    expect(undoStack.undo(), '2');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '1');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.redo(), '2');
    expect(undoStack.top, '2');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '1');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '0');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);
    expect(undoStack.undo(), '0');
    _logStack(undoStack);


    //  undo without undo data
    expect(undoStack.undo(), '0');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);


    undoStack.push('0');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);

    undoStack.push('10');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    undoStack.push('20');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    undoStack.push('30');
    expect(undoStack.top, '30');

    //  take a look
    _logStack(undoStack);

    expect(undoStack.undo(), '20');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '10');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '0');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    _logStack(undoStack);

  });
  test('test undo max', () {

    UndoStack<String> undoStack = UndoStack.withMax(3);
    expect(undoStack.canUndo, false);
    expect(undoStack.canRedo, false);

    undoStack.push('0');
    _logStack(undoStack);
    expect(undoStack.canUndo, false);
    expect(undoStack.canRedo, false);
    undoStack.push('1');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    undoStack.push('2');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    undoStack.push('3');
    expect(undoStack.top, '3');

    //  take a look
    _logStack(undoStack);

    expect(undoStack.undo(), '2');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '1');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);
    expect(undoStack.redo(), '2');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '1');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);
    expect(undoStack.undo(), '1');
    _logStack(undoStack);

    undoStack.push('0');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);

    //  undo without undo data
    expect(undoStack.undo(), '1');
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);

    undoStack.push('10');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    undoStack.push('20');
    _logStack(undoStack);
    expect(undoStack.canUndo, true);
    expect(undoStack.canRedo, false);
    undoStack.push('30');
    expect(undoStack.top, '30');

    //  take a look
    _logStack(undoStack);

    expect(undoStack.undo(), '20');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, true);
    expect(undoStack.undo(), '10');
    _logStack(undoStack);
    expect(undoStack.canRedo, true);
    expect(undoStack.canUndo, false);

  });
}
