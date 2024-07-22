import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MtuControllerProvider extends ChangeNotifier{

  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;


  void _scanForDevices() {
    _flutterBlue.scan(timeout: Duration(seconds: 5)).listen((scanResult) async {
      _flutterBlue.stopScan();
      await _connectToDevice(scanResult.device);
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();

        connectedDevice = device;
      print('Connected to ${device.name}');

      notifyListeners();
      await _setMtuSize(device, 517);

      // Send first packet
      await _sendFirstPacket(device, 'file-name', 20000, 40, 38, 25, 500, 0x52, 0x13);

      // Prepare data packet
      List<int> fileData = List.generate(500, (index) => index % 256); // Example data
      int checksum = calculateChecksum(fileData);
      int checkXor = calculateXor(fileData);

      // Send data packet
      await _sendDataPacket(device, fileData, checksum, checkXor);

    } catch (e) {
      print('Error connecting to device: $e');
    }
    notifyListeners();
  }

  Future<void> _setMtuSize(BluetoothDevice device, int mtuSize) async {
    try {
      await device.requestMtu(mtuSize);
      print('Requested MTU size of $mtuSize');
    } catch (e) {
      print('Error requesting MTU size: $e');
    }
  }

  Future<void> _sendFirstPacket(BluetoothDevice device, String fileName, int fileSize, int totalPackets, int fileChecksum, int fileCheckXor, int packetSize, int packetChecksum, int packetCheckXor) async {
    String packet = 'FTP,$fileName,$fileSize,$totalPackets,$fileChecksum,$fileCheckXor,$packetSize,0x${packetChecksum.toRadixString(16).padLeft(2, '0')}0x${packetCheckXor.toRadixString(16).padLeft(2, '0')}';
    print('Sending first packet: $packet');

    // Send packet data
    // Example: device.writeCharacteristic(characteristic, utf8.encode(packet));
  }

  Future<void> _sendDataPacket(BluetoothDevice device, List<int> data, int checksum, int checkXor) async {
    String dataHex = data.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    String packet = 'FT$dataHex${checksum.toRadixString(16).padLeft(2, '0')}${checkXor.toRadixString(16).padLeft(2, '0')}';
    print('Sending data packet: $packet');

    // Send packet data
    // Example: device.writeCharacteristic(characteristic, utf8.encode(packet));
  }

  int calculateChecksum(List<int> data) {
    int checksum = 0;
    for (var byte in data) {
      checksum += byte;
    }
    return checksum & 0xFF; // Ensure checksum is a single byte
  }
  int calculateXor(List<int> data) {
    int xor = 0;
    for (var byte in data) {
      xor ^= byte;
    }
    return xor & 0xFF; // Ensure XOR is a single byte
  }





}

final mTuControllerProvider = ChangeNotifierProvider((ref) {
  MtuControllerProvider ob =MtuControllerProvider();
  ob._scanForDevices();
  return ob;
});