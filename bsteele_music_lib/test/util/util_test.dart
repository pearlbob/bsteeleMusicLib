import 'dart:math';

import 'package:bsteeleMusicLib/util/util.dart';
import 'package:test/test.dart';

void main() {
  test('test util limit', ()
  {
    expect( Util.limit(0, 12 , 15), 12);
    expect( Util.limit(0,23 , 15), 15);
    expect( Util.limit(-12,23 , 15), 15);
    expect( Util.limit(312,23 , 15), 23);
    expect( Util.limit(null,null,null), null);
    expect( Util.limit(13,null,null), 13);
    expect( Util.limit(13,0,null), 13);
    expect( Util.limit(-13,0,null), 0);
    expect( Util.limit(13,null,23), 13);
    expect( Util.limit(123,null,23), 23);
    expect( Util.limit(-123,null,23), -123);
    expect( Util.limit(-123,null,null), -123);
    expect( Util.limit(3,e,pi), 3);
    expect( Util.limit(0,e,pi), e);
    expect( Util.limit(12,e,pi),pi);
    expect( Util.limit(12*pi,e,pi),pi);
    expect( Util.limit(2.8,e,pi),2.8);
    expect( Util.limit(double.infinity,e,pi),pi);
    expect( Util.limit(double.infinity,e,double.maxFinite),double.maxFinite);
    expect( Util.limit(0,e,double.maxFinite),e);
  });
}