import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:tray_manager/src/menu_item.dart' as tray;

import 'commands.dart';

// The starting dimensions of the window
const appDimensions = Size(300, 350);

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
  await hotKeyManager.register(
    refreshHotKey,
    keyDownHandler: (hotKey) {
      commandRefresh();
    },
    keyUpHandler: (hotKey){ });
}

void main() async {
  // Must add this line.
  WidgetsFlutterBinding.ensureInitialized();
  // For hot reload, `unregisterAll()` needs to be called.
  await hotKeyManager.unregisterAll();

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));

  doWhenWindowReady(() {
    trayManager
        .setIcon('images/monitor.png')
        .then((noValue) {
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
    switch(menuItem.title) {
      case 'Init':
        commandInitMira();
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

  void showSettingWindow() {
    trayManager.getBounds().then((rect) {
      appWindow.size = const Size(300, 280);
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
              buildContrastSlider(),
              buildBlackFilterSlider(),
              buildWhiteFilterSlider(),
              buildColdLightSlider(),
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

  double _contrast = 0.0;
  Widget buildContrastSlider() {
    return Row(
      children: [
        const Text('Contrast: '),
        Slider(
          value: _contrast,
          max: 15.0,
          onChanged: (value) {
            commandContrast(value);
            setState(() {
              _contrast = value;
            });
          },
        ),
      ],
    );
  }

  double _blackFilter = 0.0;
  Widget buildBlackFilterSlider() {
    return Row(
      children: [
        const Text('Blackness: '),
        Slider(
          value: _blackFilter,
          max: 254.0,
          onChanged: (value) {
            commandBlackFilter(value);
            setState(() {
              _blackFilter = value;
            });
          },
        ),
      ],
    );
  }
  double _whiteFilter = 0.0;
  Widget buildWhiteFilterSlider() {
    return Row(
      children: [
        const Text('Whiteness: '),
        Slider(
          value: _whiteFilter,
          max: 254.0,
          onChanged: (value) {
            commandWhiteFilter(value);
            setState(() {
              _whiteFilter = value;
            });
          },
        ),
      ],
    );
  }
  double _coldLight = 0.0;
  Widget buildColdLightSlider() {
    return Row(
      children: [
        const Text('Cold Light: '),
        Slider(
          value: _coldLight,
          max: 254.0,
          onChanged: (value) {
            commandColdLight(value);
            setState(() {
              _coldLight = value;
            });
          },
        ),
      ],
    );
  }
}

