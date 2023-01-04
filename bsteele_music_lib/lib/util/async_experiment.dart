import 'dart:async';

import 'package:worker_manager/worker_manager.dart';

void main(List<String> args) async {
  //await Executor().warmUp();
  syncExperiment();
  await Future.delayed(const Duration(seconds: 12));
  print('main done');
}

syncExperiment() async {
  //Executor().execute(arg1: 0, fun1: asyncExperiment);
  asyncExperiment();
  int count = 0;
  for (; count < 300; count++) {
    print('sync: $count');
    await Future.delayed(const Duration(milliseconds: 3));
  }
}

Future<int> asyncExperiment(// int n, TypeSendPort<dynamic> typeSendPort
    ) async {
  int count = 0;
  for (; count < 10; count++) {
    print('count: $count');
    await Future.delayed(const Duration(milliseconds: 10));
  }
  return count;
}

int asyncCompute() {
  int count = 0;
  for (; count < 10; count++) {
    print('count: $count');
    // await Future.delayed(const Duration(seconds: 1));
  }
  return count;
}
