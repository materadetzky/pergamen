/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program, if not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:folio/services/push_notification_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/database/init.dart';
import 'package:folio/models/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:folio/app.dart';
import 'package:flutter/services.dart';
import 'package:folio/utils/service_locator.dart';
import 'package:folio_mobile_ui/screens/error_screen.dart';
import 'package:folio_mobile_ui/screens/error_report_screen.dart';

import 'package:path_provider/path_provider.dart';

import 'helpers/live_activity_helper.dart';

Future<void> appendLog(String message) async {
  debugPrint('[Pergamen-Dart] $message');
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pergamen_boot.log');
    await file.writeAsString('[${DateTime.now().toIso8601String()}] [Dart] $message\n', mode: FileMode.append);
  } catch (e) {
    debugPrint('appendLog error: $e');
  }
}

// days without touching grass: 5,843 (16 yrs)

void main() async {
  try {
    WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
    await appendLog('1. WidgetsFlutterBinding initialized');
    // ignore: deprecated_member_use
    binding.renderView.automaticSystemUiAdjustment = false;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setupLocator();
    await appendLog('2. Locator setup complete');

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Firebase.initializeApp();
        await appendLog('3. Native Firebase initialized');
      } catch (e) {
        await appendLog('3. Native Firebase skipped: $e');
        if (Platform.isAndroid) {
          try {
            await Firebase.initializeApp(
              name: defaultFirebaseAppName,
              options: const FirebaseOptions(
                apiKey: "AIzaSyCmWmn9Dr4sgVgA9zFe8rI_rp3m8D07N00",
                appId: "1:94936564605:android:d578a7b50c5ef8b0294214",
                projectId: "pergamen-noti",
                messagingSenderId: "94936564605",
                storageBucket: "pergamen-noti.firebasestorage.app",
              ),
            );
            await appendLog('3. Fallback Firebase initialized');
          } catch (e2) {
            await appendLog('3. Fallback Firebase skipped: $e2');
          }
        }
      }

      try {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        await PushNotificationService.initialize();
        await appendLog('3.1. PushNotificationService initialized');
      } catch (e) {
        await appendLog('3.1. PushNotificationService skipped: $e');
      }
    }

    Startup startup = Startup();
    await appendLog('4. Calling startup.start()...');
    await startup.start();
    await appendLog('5. startup.start() finished successfully');

    ErrorWidget.builder = errorBuilder;

    try {
      BackgroundFetch.registerHeadlessTask(backgroundHeadlessTask);
    } catch (e) {
      await appendLog('[BackgroundFetch] registerHeadlessTask error: $e');
    }

    // pre-cache required icons
    const todaySvg = SvgAssetLoader('assets/svg/menu_icons/today_selected.svg');
    const gradesSvg =
        SvgAssetLoader('assets/svg/menu_icons/grades_selected.svg');
    const timetableSvg =
        SvgAssetLoader('assets/svg/menu_icons/timetable_selected.svg');
    const notesSvg = SvgAssetLoader('assets/svg/menu_icons/notes_selected.svg');
    const absencesSvg =
        SvgAssetLoader('assets/svg/menu_icons/absences_selected.svg');

    svg.cache
        .putIfAbsent(todaySvg.cacheKey(null), () => todaySvg.loadBytes(null));
    svg.cache
        .putIfAbsent(gradesSvg.cacheKey(null), () => gradesSvg.loadBytes(null));
    svg.cache.putIfAbsent(
        timetableSvg.cacheKey(null), () => timetableSvg.loadBytes(null));
    svg.cache
        .putIfAbsent(notesSvg.cacheKey(null), () => notesSvg.loadBytes(null));
    svg.cache.putIfAbsent(
        absencesSvg.cacheKey(null), () => absencesSvg.loadBytes(null));

    await appendLog('6. Calling runApp(App(...))...');
    runApp(App(
      database: startup.database,
      settings: startup.settings,
      user: startup.user,
    ));
    await appendLog('7. runApp executed');
  } catch (error, stackTrace) {
    await appendLog('FATAL DART ERROR: $error\n$stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initialization Error:\n\n$error\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class Startup {
  late SettingsProvider settings;
  late UserProvider user;
  late DatabaseProvider database;

  Future<void> start() async {
    await appendLog('Startup.start: creating DatabaseProvider');
    database = DatabaseProvider();
    await appendLog('Startup.start: calling initDB');
    var db = await initDB(database);
    await appendLog('Startup.start: closing temp db');
    await db.close();
    await appendLog('Startup.start: calling database.init()');
    await database.init();
    await appendLog('Startup.start: getSettings');
    settings = await database.query.getSettings(database);
    await appendLog('Startup.start: getUsers');
    user = await database.query.getUsers(settings);
    await appendLog('Startup.start: all DB operations complete');

    if (!kIsWeb) {
      try {
        await appendLog('Startup.start: initAdditionalBackgroundFetch');
        await initAdditionalBackgroundFetch();
        await appendLog('Startup.start: background fetch initialized');
      } catch (e) {
        await appendLog('Startup.start: background fetch error: $e');
      }
    }
  }
}

bool errorShown = false;
String lastException = '';

Widget errorBuilder(FlutterErrorDetails details) {
  return Builder(builder: (context) {
    if (Navigator.of(context).canPop()) Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!errorShown && details.exceptionAsString() != lastException) {
        errorShown = true;
        lastException = details.exceptionAsString();
        Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (context) {
          if (kReleaseMode) {
            return ErrorReportScreen(details);
          } else {
            return ErrorScreen(details);
          }
        })).then((_) => errorShown = false);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Text(
            details.exceptionAsString() +
                '\n\n' +
                (details.stack?.toString() ?? ''),
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  });
}

Future<void> initAdditionalBackgroundFetch() async {
  try {
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY,
            startOnBoot: true), (String taskId) async {
      if (kDebugMode) {
        print("[BackgroundFetch] Event received $taskId");
      }
      LiveActivityHelper liveActivityHelper = LiveActivityHelper();
      liveActivityHelper.backgroundJob();
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      if (kDebugMode) {
        print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      }
      BackgroundFetch.finish(taskId);
    });
    if (kDebugMode) {
      print('[BackgroundFetch] configure success: $status');
    }
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.folioliveactivity",
        delay: 300000, // 5 minutes
        periodic: true,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));
  } catch (e) {
    debugPrint('[BackgroundFetch] init error: $e');
  }
}

@pragma('vm:entry-point')
void backgroundHeadlessTask(HeadlessTask task) {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    if (kDebugMode) {
      print("[BackgroundFetch] Headless task timed-out: $taskId");
    }
    BackgroundFetch.finish(taskId);
    return;
  }
  if (kDebugMode) {
    print('[BackgroundFetch] Headless event received.');
  }
  if (taskId == "com.transistorsoft.folioliveactivity") {
    if (!Platform.isIOS) return;
    LiveActivityHelper().backgroundJob();
  }
  BackgroundFetch.finish(task.taskId);
}
