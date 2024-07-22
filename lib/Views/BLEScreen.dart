import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'FileTransferScreen.dart';

class BLEScreen extends StatefulWidget {
  @override
  _BLEScreenState createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> devicesList = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      startScan();
    } else {
      print("Permissions denied");
    }
  }

  void startScan() {
    if (isScanning) return;
    setState(() {
      isScanning = true;
    });

    flutterBlue.startScan(
      timeout: Duration(seconds: 10),
      scanMode: ScanMode.lowLatency,
    );

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devicesList.contains(r.device)) {
          setState(() {
            devicesList.add(r.device);
          });
        }
      }
    }).onError((error) {
      print('Error during scan: $error');
    });

    flutterBlue.stopScan().then((_) {
      setState(() {
        isScanning = false;
      });
      print("Scan stopped.");
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    print("object");
    try {
      print("connecting");
      await device.connect();
      await device.requestMtu(517);
      setState(() {
        connectedDevice = device;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileTransferScreen(device: connectedDevice!),
        ),
      );
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Widget _buildDeviceListTile(BluetoothDevice device) {
    return ListTile(
      title: Text(device.name.isNotEmpty ? device.name : device.id.toString()),
      subtitle: Text(device.id.toString()),
      onTap: () => connectToDevice(device),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE Devices')),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return _buildDeviceListTile(devicesList[index]);
        },
      ),
    );
  }
}
