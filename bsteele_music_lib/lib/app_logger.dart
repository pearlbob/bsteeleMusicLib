import 'package:logger/logger.dart';

class _AppPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return [event.message];
  }
}

var logger = Logger(
  filter: null, // Use the default LogFilter (-> only log in debug mode)
  printer: _AppPrinter(), // Use the PrettyPrinter to format and print log
  output: null, // Use the default LogOutput (-> send everything to console)
);