import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/util/base/base.state.dart';

class NavigationDrawerLeading {
  static build(onPressed) {
    return IconButton(
        icon: Image.asset('static/graphic/icon/menu.png', color: Colors.black, height: 25, width: 25),
        onPressed: onPressed);
  }
}

class NavigationDrawerComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NavigationDrawerComponentState();
}

class NavigationDrawerComponentState extends BaseState<NavigationDrawerComponent> {
  @override
  Widget render() {
    return Container(
        width: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width * 0.1),
        child: Drawer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    height: 245.0,
                    child: DrawerHeader(
                      margin: const EdgeInsets.only(bottom: 0),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.white)),
                      child: Column(
                          children: [
                            Container(height: 100, width: 100, child: CircularProgressIndicator()),
                            Column(children: [
                              Text("Eldar", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w400)),
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("+38762005152", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ])
                          ]
                      ),
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }
}
