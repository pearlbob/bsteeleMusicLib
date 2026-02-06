enum Mode {
  ionian(0), // The standard major scale (e.g., C-D-E-F-G-A-B-C).
  dorian(2), // A minor mode with a raised 6th (e.g., D-E-F-G-A-B-C-D).
  phrygian(4), // A minor mode with a lowered 2nd (e.g., E-F-G-A-B-C-D-E).
  lydian(5), // A major mode with a raised 4th (e.g., F-G-A-B-C-D-E-F).
  mixolydian(7), // A major mode with a lowered 7th (e.g., G-A-B-C-D-E-F-G).
  aeolian(9), // The natural minor scale (e.g., A-B-C-D-E-F-G-A).
  locrian(11); // A diminished mode, rarely used (e.g., B-C-D-E-F-G-A-B).

  const Mode(this.halfStep);

  final int halfStep;
}
