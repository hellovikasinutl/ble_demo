import 'package:bluetooth/RiverPod/MTUControllerProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class MTUScreen extends ConsumerWidget {
  const MTUScreen({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Scaffold(
body:  Center(
  child: ref.watch(mTuControllerProvider).connectedDevice != null
      ? Text('Connected to ${ref.watch(mTuControllerProvider).connectedDevice!.name}')
      : Text('Scanning for devices...'),
),
    );
  }
}
