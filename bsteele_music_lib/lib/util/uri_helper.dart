Uri? extractUri(String s) {
  const http = 'http://';
  Uri? uri;
  try {
    uri = Uri.parse(s);
    if (uri.hasAuthority == false) {
      //  it's missing the scheme?
      uri = Uri.parse('$http$s');
    }
  } catch (e) {
    try {
      uri = Uri.parse('$http$s');
    } catch (e) {
      //  format is too bad
      return null;
    }
  }
  return uri;
}
