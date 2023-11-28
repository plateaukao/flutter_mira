import 'dart:io';

const String mira_js_path = '/opt/homebrew/bin/mira';

void commandRefresh() async => await commandMiraJs(['refresh']);

void commandInitMira() async {
  await commandAntishake();
  await commandSpeed();
}

Future<void> commandAntishake() async => commandMiraJs(['antishake']);
Future<void> commandRead() async => await commandMiraJs(
    'settings --dither-mode 3 --contrast 7 --black-filter 10 --white-filter 12 --refresh-mode direct'
        .split(' '));

Future<void> commandSpeed() async => await commandMiraJs(
    'settings --dither-mode 0 --contrast 8 --black-filter 0 --white-filter 0 --refresh-mode a2'
        .split(' '));

Future<void> commandImage() async => await commandMiraJs(
    'settings --dither-mode 0 --contrast 7 --black-filter 0 --white-filter 0 --refresh-mode direct'
        .split(' '));

Future<void> commandVideo() async => await commandMiraJs(
    'settings --dither-mode 2 --contrast 7 --black-filter 0 --white-filter 10 --refresh-mode a2'
        .split(' '));
/*
               video: {swMode: Z.A2, contrast: 7, a2Feq: 6, ditherMode: 2, whiteFilter: 10, blackFilter: 0},
                image: {swMode: Z.DU, contrast: 7, a2Feq: 5, ditherMode: 0, whiteFilter: 0, blackFilter: 0},
                read: {swMode: Z.DU, contrast: 7, a2Feq: 5, ditherMode: 3, whiteFilter: 12, blackFilter: 10},
                text1: {swMode: Z.A2, contrast: 7, a2Feq: 6, ditherMode: 1, whiteFilter: 0, blackFilter: 0},
                speed: {swMode: Z.A2, contrast: 8, a2Feq: 7, ditherMode: 0, whiteFilter: 0, blackFilter: 0}
     */

Future<void> commandLightOff() async => await commandMiraJs(
  'settings --cold-light 0 --warm-light 0'.split(' '),
);

Future<void> commandContrast(double contrast) async => await commandMiraJs(
    'settings --contrast $contrast'.split(' '));

Future<void> commandWhiteFilter(double value) async => await commandMiraJs(
    'settings --white-filter $value'.split(' '));
Future<void> commandBlackFilter(double value) async => await commandMiraJs(
    'settings --black-filter $value'.split(' '));

Future<void> commandColdLight(double value) async => await commandMiraJs(
    'settings --cold-light $value'.split(' '));

Future<void> commandWarmLight(double value) async => await commandMiraJs(
    'settings --warm-light $value'.split(' '));

Future<void> commandMiraJs(List<String> action) async => await Process.start(
  '/opt/homebrew/bin/node',
  [mira_js_path, ...action],
);


