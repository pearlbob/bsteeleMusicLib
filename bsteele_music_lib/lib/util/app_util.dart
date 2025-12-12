//  note: keep this file dart only!

String to12(final double v, {int pad = 15}) {
  return v.toStringAsFixed(12).padLeft(pad);
}

String to9(final double v, {int pad = 12}) {
  return v.toStringAsFixed(9).padLeft(pad);
}

String to6(final double v, {int pad = 9}) {
  return v.toStringAsFixed(6).padLeft(pad);
}

String to3(final double v, {int pad = 8}) {
  return v.toStringAsFixed(3).padLeft(pad);
}

String to1(final double v, {int pad = 5}) {
  return v.toStringAsFixed(1).padLeft(pad);
}

String to0(final double v, {int pad = 5}) {
  return v.toStringAsFixed(0).padLeft(pad);
}
