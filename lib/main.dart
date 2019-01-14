import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/ui/home_page.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_welcome.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_seed.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_confirm.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_import_seed.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'colors.dart';

void main() async {
  // Setup logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  // Run app
  runApp(new StateContainer(child: new KaliumApp()));
}

class KaliumApp extends StatelessWidget {
  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarIconBrightness: Brightness.light));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KaliumF',
      theme: ThemeData(
        dialogBackgroundColor: KaliumColors.backgroundDark,
        primaryColor: KaliumColors.primary,
        accentColor: KaliumColors.primary15,
        backgroundColor: KaliumColors.backgroundDark,
        fontFamily: 'NunitoSans',
        brightness: Brightness.dark,
      ),
      localizationsDelegates: [
        KaliumLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: [Locale("en"), Locale("es"), Locale("pt")],
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return NoTransitionRoute(
              builder: (_) => Splash(),
              settings: settings,
            ); 
          case '/home':
            return NoTransitionRoute(
              builder: (_) => KaliumHomePage(),
              settings: settings,
            );
          case '/intro_welcome':
            return NoTransitionRoute(
              builder: (_) => IntroWelcomePage(),
              settings: settings,
            );
          case '/intro_backup':
            return MaterialPageRoute(
              builder: (_) => IntroBackupSeedPage(),
              settings: settings,
            );
          case '/intro_backup_confirm':
            return MaterialPageRoute(
              builder: (_) => IntroBackupConfirm(),
              settings: settings,
            );
          case '/intro_import':
            return MaterialPageRoute(
              builder: (_) => IntroImportSeedPage(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}

/// NoTransitionRoute
/// Custom route which has no transitions
class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({ WidgetBuilder builder, RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child;
  }
}

/// Splash
/// Default page route that determines if user is logged in and routes them appropriately.
class Splash extends StatefulWidget {
  @override
  SplashState createState() => new SplashState();
}

class SplashState extends State<Splash> {
  Future checkLoggedIn() async {
    // See if logged in already
    bool isLoggedIn = false;
    var seed = await Vault.inst.getSeed();
    var pin = await Vault.inst.getPin();
    // If we have a seed set, but not a pin - or vice versa
    // Then delete the seed and pin from device and start over.
    // This would mean user did not complete the intro screen completely.
    if (seed != null && pin != null) {
      isLoggedIn = true;
    } else if (seed != null && pin == null) {
      await Vault.inst.deleteSeed();
    } else if (pin != null && seed == null) {
      await Vault.inst.deletePin();
    }

    if (isLoggedIn) {
      var stateContainer = StateContainer.of(context);
      stateContainer.updateWallet(address: NanoUtil.seedToAddress(seed));
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/intro_welcome');
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarIconBrightness: Brightness.light));
    // This seems to be the earliest place we can retrieve the device Locale
    StateContainer.of(context).deviceLocale = Localizations.localeOf(context);
    SharedPrefsUtil.inst.getCurrency(StateContainer.of(context).deviceLocale).then((currency) {
      StateContainer.of(context).curCurrency = currency;
    });
    return new Scaffold(
      backgroundColor: KaliumColors.background,
    );
  }
}
