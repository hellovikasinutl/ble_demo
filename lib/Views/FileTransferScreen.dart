import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'Service.dart';

class FileTransferScreen extends StatefulWidget {
  final BluetoothDevice device;

  FileTransferScreen({required this.device});

  @override
  _FileTransferScreenState createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  String? serviceUUID;
  String? characteristicUUID;

  @override
  void initState() {
    super.initState();
    discoverServicesAndCharacteristics();
  }

  Future<void> discoverServicesAndCharacteristics() async {
    await widget.device.connect();
    List<BluetoothService> services = await widget.device.discoverServices();

    bool foundService = false;
    bool foundCharacteristic = false;

    for (BluetoothService service in services) {
      print('Discovered service: ${service.uuid}');
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print('Discovered characteristic: ${characteristic.uuid}');
        if (!foundService && !foundCharacteristic) {
          setState(() {
            serviceUUID = service.uuid.toString();
            characteristicUUID = characteristic.uuid.toString();
            foundService = true;
            foundCharacteristic = true;
          });
          break;
        }
      }
      if (foundService && foundCharacteristic) {
        break;
      }
    }

    if (serviceUUID == null || characteristicUUID == null) {
      print('Service or Characteristic UUID is still null after discovery');
    } else {
      print('Service UUID: $serviceUUID');
      print('Characteristic UUID: $characteristicUUID');
    }

    await widget.device.disconnect();
  }

  void selectAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        File file = File(filePath);
        if (serviceUUID != null && characteristicUUID != null) {
          sendFile(file, widget.device, serviceUUID!, characteristicUUID!);
        } else {
          print('Service or Characteristic UUID is null');
        }
      } else {
        print('Error: File path is null');
      }
    } else {
      print('User canceled the file picker');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Transfer')),
      body: Center(
        child: ElevatedButton(
          onPressed: selectAndSendFile,
          child: Text('Select and Send File'),
        ),
      ),
    );
  }
}
