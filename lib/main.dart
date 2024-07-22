import 'package:bluetooth/Views/BLEScreen.dart';
import 'package:bluetooth/Views/MainHomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  
  
    runApp(ProviderScope(child: MyApp()));

}
 
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: MainHomeScreen(),
      home: BLEScreen(),
    );
  }
}



class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  String? _filePath;
  List<ScanResult> _scanResults = [];
  BluetoothCharacteristic? _characteristic;

  @override
  void initState() {
    super.initState();
    _scanForDevices();
  }

  void _scanForDevices() {
    _flutterBlue.scan(timeout: Duration(seconds: 5)).listen((scanResult) {
      setState(() {
        _scanResults.add(scanResult);
      });
    }).onDone(() {
      _flutterBlue.stopScan();
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
      });
      print('Connected to ${device.name}');

      await _setMtuSize(device, 517);
      _characteristic = await _getCharacteristic(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> _setMtuSize(BluetoothDevice device, int mtuSize) async {
    try {
      await device.requestMtu(mtuSize);
      print('Requested MTU size of $mtuSize for ${device.name}');
    } catch (e) {
      print('Error requesting MTU size for ${device.name}: $e');
    }
  }

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
      print('Selected file: $_filePath');
    }
  }

  Future<BluetoothCharacteristic?> _getCharacteristic(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            return characteristic;
          }
        }
      }
    } catch (e) {
      print('Error discovering services or characteristics: $e');
    }
    return null;
  }

  Future<void> _sendFile() async {
    if (_filePath == null || _connectedDevice == null || _characteristic == null) return;

    File file = File(_filePath!);
    Uint8List fileData = await file.readAsBytes();
    int checksum = calculateChecksum(fileData);
    int xor = calculateXor(fileData);
    int packetSize = 500; // Example packet size

    try {
      await _sendFirstPacket(_characteristic!, fileData, packetSize, checksum, xor);
      await _sendDataPackets(_characteristic!, fileData, packetSize);
    } catch (e) {
      print('Error sending file: $e');
    }
  }

  Future<void> _sendFirstPacket(BluetoothCharacteristic characteristic, Uint8List fileData, int packetSize, int checksum, int xor) async {
    int totalPackets = (fileData.length / packetSize).ceil();
    String fileName = _filePath!.split('/').last;
    String firstPacket = 'FTP,$fileName,${fileData.length},$totalPackets,$checksum,$xor,$packetSize,0x${checksum.toRadixString(16).padLeft(2, '0')}0x${xor.toRadixString(16).padLeft(2, '0')}';

    print('Sending first packet: $firstPacket');

    await characteristic.write(utf8.encode(firstPacket));

    // Optionally wait for acknowledgment
  }

  Future<void> _sendDataPackets(BluetoothCharacteristic characteristic, Uint8List fileData, int packetSize) async {
    int offset = 0;
    while (offset < fileData.length) {
      int end = (offset + packetSize) > fileData.length ? fileData.length : offset + packetSize;
      Uint8List packetData = fileData.sublist(offset, end);
      int checksum = calculateChecksum(packetData);
      int xor = calculateXor(packetData);

      String dataHex = packetData.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      String dataPacket = 'FT$dataHex${checksum.toRadixString(16).padLeft(2, '0')}${xor.toRadixString(16).padLeft(2, '0')}';

      print('Sending data packet: $dataPacket');

      await characteristic.write(utf8.encode(dataPacket));

      // Optionally wait for acknowledgment

      offset = end;
    }
  }

  int calculateChecksum(Uint8List data) {
    int checksum = 0;
    for (var byte in data) {
      checksum += byte;
    }
    return checksum & 0xFF;
  }

  int calculateXor(Uint8List data) {
    int xor = 0;
    for (var byte in data) {
      xor ^= byte;
    }
    return xor & 0xFF;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth File Transfer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _selectFile,
              child: Text('Select File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendFile,
              child: Text('Send File'),
            ),
            SizedBox(height: 20),
            Text(_connectedDevice != null ? 'Connected to ${_connectedDevice!.name}' : 'No device connected'),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final scanResult = _scanResults[index];
                  return ListTile(
                    title: Text(scanResult.device.name.isNotEmpty
                        ? scanResult.device.name
                        : 'Unnamed Device'),
                    subtitle: Text(scanResult.device.id.toString()),
                    onTap: () async {
                      await _connectToDevice(scanResult.device);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
