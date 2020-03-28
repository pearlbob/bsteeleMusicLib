import 'package:bsteeleMusicLib/appLogger.dart';
import 'package:bsteeleMusicLib/songs/pitch.dart';

class Bass{
    static int mapPitchToBass( Pitch pitch ){
        //  deal with the piano numbers starting on A instead of E
        return( pitch.getNumber() + 5 ) % 12;
    }
}