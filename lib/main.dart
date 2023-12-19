import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mira/theme.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:process_run/shell.dart';

//import 'package:quick_usb/quick_usb.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:tray_manager/src/menu_item.dart' as tray;
//import 'package:hid_macos/hid_macos.dart';

import 'commands.dart';

final miraDisplay = MiraDisplay();

// The starting dimensions of the window
const appDimensions = Size(240, 430);

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
    miraDisplay.commandRefresh();
  }, keyUpHandler: (hotKey) {});

  HotKey escHotKey = HotKey(
    KeyCode.escape,
    scope: HotKeyScope.inapp,
  );
  await hotKeyManager.register(escHotKey, keyDownHandler: (hotKey) {
    appWindow.hide();
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
  await miraDisplay.init();

  runApp(const MyApp());

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
      showSettingWindow();
      //trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    switch (menuItem.title) {
      case 'Init':
        _initMira();
        break;
      case 'Antishake':
        miraDisplay.commandAntishake();
        break;
      case 'Speed':
        miraDisplay.commandSpeed();
        break;
      case 'Image':
        miraDisplay.commandImage();
        break;
      case 'Read':
        miraDisplay.commandRead();
        break;
      case 'Video':
        miraDisplay.commandVideo();
        break;
      case 'Light Off':
        miraDisplay.commandLightOff();
        break;
      case 'Refresh':
        miraDisplay.commandRefresh();
        break;
      case 'Settings':
        showSettingWindow();
        break;
      case 'Quit':
        exit(0);
    }
  }

  //final HidPluginMacOS _hidPluginMacOS = HidPluginMacOS();

  void _initMira() async {
    miraDisplay.commandInitMira();

    // final devices = await _hidPluginMacOS.getDeviceList();
    // if (devices.any((e) => e.productName == 'BOOX Mira133')) {
    //   final device = devices
    //       .firstWhere((e) => e.vendorId == 0x0416 && e.productId == 0x5020);
    //   await device.open();
    //   await device.write(Uint8List.fromList([0x00, 0x01]));
    //   await device.close();
    //   print('descriptions $device');
    // }
    // await QuickUsb.init();
    // var descriptions = await QuickUsb.getDevicesWithDescription();
    // if (descriptions.any((e) => e.product == 'BOOX Mira133')) {
    //   final device = descriptions.firstWhere((e) => e.device.vendorId == 0x0416 && e.device.productId == 0x5020);
    //   await QuickUsb.openDevice(device.device);
    //   final conf = await QuickUsb.getConfiguration(0);
    //   final interf = conf.interfaces.first;
    //   bool succeed = await QuickUsb.claimInterface(interf);
    //   await QuickUsb.bulkTransferOut(interf.endpoints[1], Uint8List.fromList([0x00, 0x01]));
    //   await QuickUsb.releaseInterface(interf);
    //   QuickUsb.closeDevice();
    //   print('descriptions $device');
    // }
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
    final platform = PlatformDispatcher.instance;
    return MaterialApp(
      title: 'Mira App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: platform.platformBrightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
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
  void initState() {
    _options.firstWhere((e) => e.label == 'Contrast').value =
        miraDisplay.currentMiraModeOptions.contrast;
    _options.firstWhere((e) => e.label == 'Black').value =
        miraDisplay.currentMiraModeOptions.black;
    _options.firstWhere((e) => e.label == 'White').value =
        miraDisplay.currentMiraModeOptions.white;
    _options.firstWhere((e) => e.label == 'Speed').value =
        miraDisplay.currentMiraModeOptions.speed;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModesWidget(context),
              _buildFunctionWidget(context),
              ..._options.map((e) => _buildOptionWidget(context, e)),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                        onPressed: () => appWindow.hide(),
                        child: Text('Close',
                            style: Theme.of(context).textTheme.bodyLarge,
                            )
                        ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey),
                  IconButton(
                    onPressed: () => exit(0),
                    icon: const Icon(
                      Icons.power_settings_new,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModesWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ..._modes.map((e) => _buildOutlinedButton(context, e)),
      ],
    );
  }

  Widget _buildOutlinedButton(BuildContext context, MiraMode mode) =>
      IconButton(
        onPressed: () async {
          await mode.command();
          updateOptions();
        },
        icon: Icon(
          mode.iconId,
          color: Theme.of(context).iconTheme.color,
        ),
        style: OutlinedButton.styleFrom(
            side: BorderSide(
          color: miraDisplay.getModeLabel() == mode.label
              ? Colors.blue
              : Theme.of(context).dividerColor,
          width: 2.0,
        )),
      );

  void updateOptions() {
    setState(() {
      _options.firstWhere((e) => e.label == 'Contrast').value =
          miraDisplay.currentMiraModeOptions.contrast;
      _options.firstWhere((e) => e.label == 'Black').value =
          miraDisplay.currentMiraModeOptions.black;
      _options.firstWhere((e) => e.label == 'White').value =
          miraDisplay.currentMiraModeOptions.white;
      _options.firstWhere((e) => e.label == 'Speed').value =
          miraDisplay.currentMiraModeOptions.speed;
    });
  }

  Widget _buildFunctionWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
            onPressed: () => miraDisplay.commandInitMira(),
            child: Text('Init', style: Theme.of(context).textTheme.bodySmall,)),
        IconButton(
          onPressed: () => miraDisplay.commandLightOff(),
          icon: Icon(Icons.light, color: Theme.of(context).iconTheme.color),
        ),
        IconButton(
          onPressed: () => miraDisplay.commandRefresh(),
          icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
        ),
        IconButton(
            onPressed: () => miraDisplay.commandAntishake(),
            icon: Icon(Icons.waves, color: Theme.of(context).iconTheme.color)),
      ],
    );
  }

  Widget _buildOptionWidget(BuildContext context, MiraOption option) {
    return Row(
      children: [
        Icon(
          option.iconId,
        ),
        //Text(option.label),
        Text(option.value.toInt().toString().padLeft(3)),
        Slider(
          value: option.value,
          min: (option.label == 'Speed') ? 1.0 : 0.0,
          max: option.maxValue,
          divisions: (option.label == 'Speed') ? 6 : null,
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
    MiraOption(
        'Contrast', Icons.contrast, 13.0, 0, miraDisplay.commandContrast),
    MiraOption('Black', Icons.circle, 40.0, 0, miraDisplay.commandBlackFilter),
    MiraOption('White', Icons.circle_outlined, 40.0, 10,
        miraDisplay.commandWhiteFilter),
    MiraOption(
        'Speed', Icons.directions_run, 7.0, 7.0, miraDisplay.commandSpeedValue),
    MiraOption('Cold', Icons.wb_iridescent_outlined, 80.0, 0,
        miraDisplay.commandColdLight),
    MiraOption('Warm', Icons.wb_incandescent_outlined, 80.0, 0,
        miraDisplay.commandWarmLight),
  ];

  final _modes = [
    MiraMode('Video', Icons.play_circle, miraDisplay.commandVideo),
    MiraMode('Speed', Icons.flash_on, miraDisplay.commandSpeed),
    MiraMode('Image', Icons.image, miraDisplay.commandImage),
    MiraMode('Read', Icons.chrome_reader_mode, miraDisplay.commandRead),
  ];
}

class MiraMode {
  final String label;
  final IconData iconId;
  final Function command;

  MiraMode(this.label, this.iconId, this.command);
}

class MiraOption {
  final String label;
  final IconData iconId;
  final double maxValue;
  double value;
  final Function onChange;

  MiraOption(this.label, this.iconId, this.maxValue, this.value, this.onChange);
}
