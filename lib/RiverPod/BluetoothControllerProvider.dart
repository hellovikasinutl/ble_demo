import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothControllerProvider extends ChangeNotifier{

  FlutterBlue blue = FlutterBlue.instance;


  scanDevice()async{
    if(await Permission.bluetoothScan.request().isGranted){
      if(await Permission.bluetoothConnect.request().isGranted){
        blue.startScan(timeout: Duration(seconds: 10));
        blue.stopScan();
      }

    }

  }

  Stream<List<ScanResult>> get scanResult => blue.scanResults;

  connectToDevice(BluetoothDevice device)async{
    print("this is device$device");
    await device?.connect(timeout: Duration(seconds: 30));
    device?.state.listen((isConnected){
      if(isConnected== BluetoothDeviceState.connecting){
        print("Device is Connecting");
      }
      else if(isConnected == BluetoothDeviceState.connected){

        print("Device is Connected");
      }
      else{

        print("Device is disconnected");
      }
    });
  }

}

final bluetoothControllerProvider = ChangeNotifierProvider((ref)=>BluetoothControllerProvider());