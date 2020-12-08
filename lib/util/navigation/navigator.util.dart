
import 'package:flutter/cupertino.dart';

class NavigatorUtil {
  static push(context, activity) {
    return Navigator.of(context).push(CupertinoPageRoute(builder: (context) => activity));
  }

  static replace(context, activity) {
    return Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => activity));
  }

  static replaceWithArguments(context, activity, route, arguments) {
    return Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => activity,
            settings: RouteSettings(name: route, arguments: arguments)));
  }

  static pushWithArguments(context, activity, route, arguments) {
    return Navigator.of(context).push(
        CupertinoPageRoute(builder: (context) => activity,
            settings: RouteSettings(name: route, arguments: arguments)));
  }
}
