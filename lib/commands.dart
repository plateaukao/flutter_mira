import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/*
video: {swMode: Z.A2, contrast: 7, a2Feq: 6, ditherMode: 2, whiteFilter: 10, blackFilter: 0},
image: {swMode: Z.DU, contrast: 7, a2Feq: 5, ditherMode: 0, whiteFilter: 0, blackFilter: 0},
read: {swMode: Z.DU, contrast: 7, a2Feq: 5, ditherMode: 3, whiteFilter: 12, blackFilter: 10},
text1: {swMode: Z.A2, contrast: 7, a2Feq: 6, ditherMode: 1, whiteFilter: 0, blackFilter: 0},
speed: {swMode: Z.A2, contrast: 8, a2Feq: 7, ditherMode: 0, whiteFilter: 0, blackFilter: 0}
*/


class MiraDisplay {
  static const String miraJsPath = '/opt/homebrew/bin/mira';
  static const String spMode = 'sp_mode';
  static const String spSpeed = 'sp_speed';
  static const String spImage = 'sp_image';
  static const String spVideo = 'sp_video';
  static const String spRead = 'sp_read';

  static const String _miraModeDefaultString = '{"contrast":0,"black":0,"white":0,"speed":7}';
  MiraModeOptions currentMiraModeOptions = MiraModeOptions.fromJsonString(_miraModeDefaultString);

  late SharedPreferences prefs;
  init() async {
    prefs = await SharedPreferences.getInstance();
    currentMiraModeOptions = getModeOptions(getModeLabel());
  }

  String getModeLabel() => prefs.getString(spMode) ?? 'Image';


  MiraModeOptions getModeOptions(String miraMode) {
    switch(miraMode) {
      case 'Image':
        return MiraModeOptions.fromJson(jsonDecode(prefs.getString(spImage) ?? _miraModeDefaultString));
      case 'Speed':
        return MiraModeOptions.fromJson(jsonDecode(prefs.getString(spSpeed) ?? _miraModeDefaultString));
      case 'Video':
        return MiraModeOptions.fromJson(jsonDecode(prefs.getString(spVideo) ?? _miraModeDefaultString));
      case 'Read':
        return MiraModeOptions.fromJson(jsonDecode(prefs.getString(spRead) ?? _miraModeDefaultString));
      default:
        return MiraModeOptions.fromJson(jsonDecode(prefs.getString(spImage) ?? _miraModeDefaultString));
    }
  }

  Future<void> setModeOptions() async {
    final miraMode = prefs.getString(spMode) ?? 'Image';
    switch(miraMode) {
      case 'Image':
        prefs.setString(spImage, jsonEncode(currentMiraModeOptions.toJson()));
        break;
      case 'Speed':
        prefs.setString(spSpeed, jsonEncode(currentMiraModeOptions.toJson()));
        break;
      case 'Video':
        prefs.setString(spVideo, jsonEncode(currentMiraModeOptions.toJson()));
        break;
      case 'Read':
        prefs.setString(spRead, jsonEncode(currentMiraModeOptions.toJson()));
        break;
    }
  }

  Future<void> commandRefresh() async =>
      await commandMiraJs(['refresh']);

  Future<void> commandInitMira() async {
    await commandAntishake();
    await commandSpeed();
  }

  Future<void> commandAntishake() async =>
      commandMiraJs(['antishake']);

  Future<void> commandRead() async {
    await prefs.setString(spMode, 'Read');

    currentMiraModeOptions = getModeOptions('Read');
    await commandMiraJs(
          'settings --dither-mode 3 --contrast ${currentMiraModeOptions.contrast} --black-filter ${currentMiraModeOptions.black} --white-filter ${currentMiraModeOptions.white} --speed ${currentMiraModeOptions.speed} --refresh-mode direct'
              .split(' '));
  }

  Future<void> commandSpeed() async {
    await prefs.setString(spMode, 'Speed');

    currentMiraModeOptions = getModeOptions('Speed');
    await commandMiraJs(
          'settings --dither-mode 0 --contrast ${currentMiraModeOptions.contrast} --black-filter ${currentMiraModeOptions.black} --white-filter ${currentMiraModeOptions.white} --speed ${currentMiraModeOptions.speed} --refresh-mode a2'
              .split(' '));
  }

  Future<void> commandImage() async {
    await prefs.setString(spMode, 'Image');

    currentMiraModeOptions = getModeOptions('Image');
    await commandMiraJs(
          'settings --dither-mode 0 --contrast ${currentMiraModeOptions.contrast} --black-filter ${currentMiraModeOptions.black} --white-filter ${currentMiraModeOptions.white} --speed ${currentMiraModeOptions.speed} --refresh-mode direct'
              .split(' '));
  }

  Future<void> commandVideo() async {
    await prefs.setString(spMode, 'Video');

    currentMiraModeOptions = getModeOptions('Video');
    await commandMiraJs(
      'settings --dither-mode 2 --contrast ${currentMiraModeOptions.contrast} --black-filter ${currentMiraModeOptions.black} --white-filter ${currentMiraModeOptions.white} --speed ${currentMiraModeOptions.speed} --refresh-mode a2'
          .split(' '));
  }

  Future<void> commandLightOff() async {
    prefs.setDouble('cold-light', 0);
    prefs.setDouble('warm-light', 0);

    await commandMiraJs(
    'settings --cold-light 0 --warm-light 0'.split(' '),
  );
  }

  Future<void> commandContrast(double contrast) async {
    currentMiraModeOptions.contrast = contrast;
    setModeOptions();

    await commandMiraJs(
      'settings --contrast $contrast'.split(' '));
  }

  Future<void> commandSpeedValue(double speed) async {
    currentMiraModeOptions.speed = speed;
    setModeOptions();

    await commandMiraJs(
      'settings --speed $speed'.split(' '));
  }

  Future<void> commandWhiteFilter(double value) async {
    currentMiraModeOptions.white = value;
    setModeOptions();

    await commandMiraJs(
      'settings --black-filter ${currentMiraModeOptions.black} --white-filter $value'.split(' '));
  }

  Future<void> commandBlackFilter(double value) async {
    currentMiraModeOptions.black = value;
    setModeOptions();

    await commandMiraJs(
      'settings --white-filter ${currentMiraModeOptions.white} --black-filter $value'.split(' '));
  }

  Future<void> commandColdLight(double value) async {
    prefs.setDouble('cold-light', value);

    await commandMiraJs(
      'settings --cold-light $value'.split(' '));
  }

  Future<void> commandWarmLight(double value) async {
    prefs.setDouble('warm-light', value);

    await commandMiraJs(
      'settings --warm-light $value'.split(' '));
  }

  Future<void> commandMiraJs(List<String> action) async => await Process.start(
    '/opt/homebrew/bin/node',
    [miraJsPath, ...action],
  );
}

class MiraModeOptions {
  double contrast;
  double black;
  double white;
  double speed;

  MiraModeOptions({required this.contrast, required this.black, required this.white, required this.speed});

  // Convert a MiraMode object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'contrast': contrast,
      'black': black,
      'white': white,
      'speed': speed,
    };
  }

  // Create a MiraMode object from a map
  factory MiraModeOptions.fromJson(Map<String, dynamic> json) {
    return MiraModeOptions(
      contrast: json['contrast'].toDouble(),
      black: json['black'].toDouble(),
      white: json['white'].toDouble(),
      speed: json['speed'].toDouble(),
    );
  }

  // Create a MiraMode object from a JSON string
  static MiraModeOptions fromJsonString(String jsonString) {
    return MiraModeOptions.fromJson(jsonDecode(jsonString));
  }
}
