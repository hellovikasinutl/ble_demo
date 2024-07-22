import 'package:bluetooth/Helper/Layout.dart';
import 'package:bluetooth/RiverPod/BluetoothControllerProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainHomeScreen extends ConsumerWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var height = Layout().height;
    var width = Layout().width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Scanner"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<List<ScanResult>>(
              stream: ref.watch(bluetoothControllerProvider).scanResult,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      print("Device is Lenght is ${snapshot.data!.length}");
                      final data = snapshot.data![index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          onTap: (){
                            ref.read(bluetoothControllerProvider).connectToDevice(data.device);
                          },
                          title: Text(data.device.name.isEmpty ? 'Unnamed Device' : data.device.name),
                          subtitle: Text(data.device.id.id),
                          trailing: Text(data.rssi.toString()),
                        ),

                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text("No Device Found"),
                  );
                }
              },
            ),

            SizedBox(
              height: height * 0.05,
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: InkWell(
        onTap: () {
          ref.read(bluetoothControllerProvider).scanDevice();
        },
        child: Container(
          width: width * 0.5,
          height: height * 0.05,
          alignment: Alignment.center,
          child: Text(
            "Scan",
            style: TextStyle(
              fontSize: height * 0.02,
              fontWeight: FontWeight.w600,
            ),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
