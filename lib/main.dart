import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:process_run/shell.dart';
import 'package:quick_usb/quick_usb.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:tray_manager/src/menu_item.dart' as tray;

import 'commands.dart';

// The starting dimensions of the window
const appDimensions = Size(260, 300);

void updateTrayIcon(Brightness brightness) {
  if (brightness == Brightness.light) {
    trayManager.setIcon('images/monitor.png');
  } else {
    trayManager.setIcon('images/monitor_white.png');
  }
}

void initBrightness() {
  final platform = PlatformDispatcher.instance;
  updateTrayIcon(platform.platformBrightness);
  platform.onPlatformBrightnessChanged =
      () => updateTrayIcon(platform.platformBrightness);
}

void initHotkeys() async {
  HotKey refreshHotKey = HotKey(
    KeyCode.keyR,
    modifiers: [KeyModifier.control, KeyModifier.alt, KeyModifier.meta],
    scope: HotKeyScope.system,
  );
  await hotKeyManager.register(refreshHotKey, keyDownHandler: (hotKey) {
    commandRefresh();
  }, keyUpHandler: (hotKey) {});
}

void initTrayManager() {
  trayManager.setIcon('images/monitor.png').then((noValue) {
    var listener = TrayClickListener();
    trayManager.addListener(listener);
    if (kDebugMode) {
      // In dev mode, go ahead and open the app
      // NOTE: It doesn't look like the app is positioned correctly when doing this, but for the sake of development
      // it should be fine
      listener.onTrayIconMouseUp();
    }
  });
  trayManager.setContextMenu([
    tray.MenuItem(title: 'Init'),
    tray.MenuItem.separator,
    tray.MenuItem(title: 'Speed'),
    tray.MenuItem(title: 'Image'),
    tray.MenuItem(title: 'Read'),
    tray.MenuItem(title: 'Video'),
    tray.MenuItem.separator,
    tray.MenuItem(title: 'Light Off'),
    tray.MenuItem(title: 'Refresh'),
    tray.MenuItem(title: 'Antishake'),
    tray.MenuItem.separator,
    tray.MenuItem(title: 'Settings'),
    tray.MenuItem(title: 'Quit'),
  ]);
}

void main() async {
  // Must add this line.
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();

  final platform = PlatformDispatcher.instance;
  runApp(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: platform.platformBrightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MyApp()));

  doWhenWindowReady(() {
    initTrayManager();
    initBrightness();
    initHotkeys();
  });
}

/// This handles clicking on the tray icon
class TrayClickListener extends TrayListener {
  @override
  void onTrayIconRightMouseUp() {
    if (appWindow.isVisible) {
      appWindow.hide();
    } else {
      showSettingWindow();
    }
  }

  @override
  void onTrayIconMouseUp() {
    if (appWindow.isVisible) {
      appWindow.hide();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    switch (menuItem.title) {
      case 'Init':
        _initMira();
        break;
      case 'Antishake':
        commandAntishake();
        break;
      case 'Speed':
        commandSpeed();
        break;
      case 'Image':
        commandImage();
        break;
      case 'Read':
        commandRead();
        break;
      case 'Video':
        commandVideo();
        break;
      case 'Light Off':
        commandLightOff();
        break;
      case 'Refresh':
        commandRefresh();
        break;
      case 'Settings':
        showSettingWindow();
        break;
      case 'Quit':
        exit(0);
    }
  }

  void _initMira() async {
    //commandInitMira();
    await QuickUsb.init();
    var descriptions = await QuickUsb.getDevicesWithDescription();
    if (descriptions.any((e) => e.product == 'BOOX Mira133')) {
      final device = descriptions.firstWhere((e) => e.device.vendorId == 0x0416 && e.device.productId == 0x5020);
      await QuickUsb.openDevice(device.device);
      UsbConfiguration conf = UsbConfiguration(id: 1, index: 0, interfaces: []);
      await QuickUsb.setConfiguration(conf);
      QuickUsb.closeDevice();
      print('descriptions $device');
      print('conf $conf');
    }
  }

  void showSettingWindow() {
    trayManager.getBounds().then((rect) {
      appWindow.size = appDimensions;
      var x = rect.left > rect.top ? rect.left : rect.top;
      var y = x == rect.left ? rect.top : rect.left;
      // Set the position so the icon is above the middle of the window
      appWindow.position = Offset(x - (appDimensions.width / 2), y + 4);
      appWindow.title = 'Mira Menubar App';
      appWindow.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mira App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mira App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._options.map((e) => buildOptionWidget(context, e)),
              const Divider(),
              TextButton(
                onPressed: () {
                  appWindow.hide();
                  //exit(0);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOptionWidget(BuildContext context, MiraOption option) {
    return Row(
      children: [
        Icon(
          option.iconId,
          color: Theme.of(context).primaryColor,
        ),
        //Text(option.label),
        Text(option.value.toInt().toString().padLeft(3),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
            )),
        Slider(
          value: option.value,
          max: option.maxValue,
          onChanged: (value) {
            option.onChange(value);
            setState(() {
              option.value = value;
            });
          },
        ),
      ],
    );
  }

  final _options = [
    MiraOption('Contrast', Icons.contrast, 15.0, 0, commandContrast),
    MiraOption('Black', Icons.circle, 254.0, 0, commandBlackFilter),
    MiraOption('White', Icons.circle_outlined, 254.0, 10, commandWhiteFilter),
    MiraOption('Cold', Icons.wb_iridescent, 254.0, 0, commandColdLight),
    MiraOption('Warm', Icons.wb_incandescent, 254.0, 0, commandWarmLight),
  ];
}

class MiraOption {
  final String label;
  final IconData iconId;
  final double maxValue;
  double value;
  final Function onChange;

  MiraOption(this.label, this.iconId, this.maxValue, this.value, this.onChange);
}
