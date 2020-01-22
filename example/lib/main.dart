// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';
import 'package:audioplayers/audio_cache.dart';

var ping;
var pingDelay = 1000;
var pingCounter = 0;
var pingCountMax = 5;
var pingSecondsMax = 15;

startPing() {
  cancelPing("Cancelling ping to restart");
  ping = Timer.periodic(Duration(milliseconds: pingDelay), (ping) {
    print('Ping: $pingCounter at ${DateTime.now()}');
    // https://stackoverflow.com/questions/43813386/how-to-play-a-custom-sound-in-flutter
    // https://pub.dev/packages/audioplayers
    AudioCache audioCache = new AudioCache();
    audioCache.play('ping.mp3');
    pingCounter++;
    if (pingCounter >= pingCountMax) {
      print("Cancelling ping after $pingCountMax iterations");
      ping.cancel();
    }
  });
}

cancelPing([String message]) {
  if (ping !=null && ping.isActive) {
    if(message != null) {
      print(message);
    }
    ping.cancel();
    pingCounter = 0;
  }
}

void main() {
  Timer(Duration(seconds: pingSecondsMax), () {
    cancelPing("Cancelling ping after $pingSecondsMax seconds");
  });

  runApp(FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state.toString().substring(15)}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      startPing(); // Start pinging with the initial delay

    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .where((r) => r.device.name.startsWith('wind')) // filter only windup
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}