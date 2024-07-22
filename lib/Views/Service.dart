import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';

Future<void> sendFile(File file, BluetoothDevice device, String serviceUUID, String characteristicUUID) async {
  List<int> fileBytes = await file.readAsBytes();
  int fileSize = fileBytes.length;
  String fileName = file.uri.pathSegments.last;
  int totalPackets = (fileSize / 500).ceil();
  int fileChecksum = calculateChecksum(fileBytes);
  int fileCheckXor = calculateCheckXor(fileBytes);
  String firstPacket = 'FTP$fileName$fileSize$totalPackets${fileChecksum.toRadixString(16)}${fileCheckXor.toRadixString(16)}500&';


  await sendPacket(firstPacket, device, serviceUUID, characteristicUUID);

  for (int i = 0; i < totalPackets; i++) {
    int start = i * 500;
    int end = start + 500 > fileSize ? fileSize : start + 500;
    List<int> chunk = fileBytes.sublist(start, end);
    int chunkChecksum = calculateChecksum(chunk);
    int chunkCheckXor = calculateCheckXor(chunk);
    String dataPacket = 'FT${chunk.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}${chunkChecksum.toRadixString(16)}${chunkCheckXor.toRadixString(16)}';
    await sendPacket(dataPacket, device, serviceUUID, characteristicUUID);
  }
}

Future<void> sendPacket(String packet, BluetoothDevice device, String serviceUUID, String characteristicUUID) async {
  List<BluetoothService> services = await device.discoverServices();
  try {
    BluetoothService service = services.firstWhere((service) => service.uuid.toString() == serviceUUID);
    BluetoothCharacteristic characteristic = service.characteristics.firstWhere((char) => char.uuid.toString() == characteristicUUID);

    await characteristic.write(packet.codeUnits);
  } catch (e) {
    print('Error: $e');
  }
}

int calculateChecksum(List<int> data) {
  int checksum = 0;
  for (int byte in data) {
    checksum += byte;
  }
  return checksum & 0xFF;
}

int calculateCheckXor(List<int> data) {
  int checkXor = 0;
  for (int byte in data) {
    checkXor ^= byte;
  }
  return checkXor & 0xFF;
}
