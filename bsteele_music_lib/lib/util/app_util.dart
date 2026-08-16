//  note: keep this file dart only!

String to16(double v, {int pad = 16 + 3}) {
  return v.toStringAsFixed(16).padLeft(pad);
}

String to12(double v, {int pad = 15}) {
  return v.toStringAsFixed(12).padLeft(pad);
}

String to9(double v, {int pad = 12}) {
  return v.toStringAsFixed(9).padLeft(pad);
}

String to6(double v, {int pad = 9}) {
  return v.toStringAsFixed(6).padLeft(pad);
}

String to3(double v, {int pad = 8}) {
  return v.toStringAsFixed(3).padLeft(pad);
}

String to2(double v, {int pad = 7}) {
  return v.toStringAsFixed(2).padLeft(pad);
}

String to1(double v, {int pad = 5}) {
  return v.toStringAsFixed(1).padLeft(pad);
}

String to0(double v, {int pad = 5}) {
  return v.round().toString().padLeft(pad);
}

String iTo2(int i) {
  return i.toString().padLeft(2);
}

String iTo3(int i) {
  return i.toString().padLeft(3);
}

String iTo4(int i) {
  return i.toString().padLeft(4);
}

String iTo5(int i) {
  return i.toString().padLeft(5);
}

String iTo6(int i) {
  return i.toString().padLeft(6);
}
