import 'package:flutter/material.dart';
import 'package:flutterping/service/voice/sip-client.service.dart';
import 'package:flutterping/shared/component/action-button.component.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DialpadActivity extends StatefulWidget {
  final String destination;

  const DialpadActivity({Key key, this.destination}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new DialpadActivityState();
}

class DialpadActivityState extends State<DialpadActivity> {
  TextEditingController _textController;

  String receivedMsg;

  @override
  initState() {
    super.initState();
    receivedMsg = "";
    _loadSettings();
  }

  void _loadSettings() async {
    _textController = TextEditingController(text: widget.destination);
    _textController.text = widget.destination;

    this.setState(() {});
  }

  Widget _handleCall(BuildContext context, [bool voiceonly = false]) {
    var dest = 'sip:' + widget.destination + '@46.101.169.71';
    if (dest == null || dest.isEmpty) {
      showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Target is empty.'),
            content: Text('Please enter a SIP URI or username!'),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return null;
    }
    sipClientService.call(dest);
    return null;
  }

  void _handleBackSpace([bool deleteAll = false]) {
    var text = _textController.text;
    if (text.isNotEmpty) {
      this.setState(() {
        text = deleteAll ? '' : text.substring(0, text.length - 1);
        _textController.text = text;
      });
    }
  }

  void _handleNum(String number) {
    this.setState(() {
      _textController.text += number;
    });
  }

  List<Widget> _buildNumPad() {
    var lables = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return lables
        .map((row) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((label) => ActionButton(
              onPressed: () => _handleNum(label.keys.first),
            ))
                .toList())))
        .toList();
  }

  List<Widget> _buildDialPad() {
    return [
      Container(
          width: 360,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    width: 360,
                    child: TextField(
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.black54),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                      ),
                      controller: _textController,
                    )),
              ])),
      Container(
          width: 300,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildNumPad())),
      Container(
          width: 300,
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ActionButton(
                    icon: Icons.videocam,
                    onPressed: () => _handleCall(context),
                  ),
                  ActionButton(
                    icon: Icons.dialer_sip,
                    fillColor: Colors.green,
                    onPressed: () => _handleCall(context, true),
                  ),
                  ActionButton(
                    icon: Icons.keyboard_arrow_left,
                    onPressed: () => _handleBackSpace(),
                  ),
                ],
              )))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Dart SIP UA Demo"),
          actions: <Widget>[
            PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'account':
                      Navigator.pushNamed(context, '/register');
                      break;
                    case 'about':
                      Navigator.pushNamed(context, '/about');
                      break;
                    default:
                      break;
                  }
                },
                icon: Icon(Icons.menu),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Icon(
                            Icons.account_circle,
                            color: Colors.black38,
                          ),
                        ),
                        SizedBox(
                          child: Text('Account'),
                          width: 64,
                        )
                      ],
                    ),
                    value: 'account',
                  ),
                  PopupMenuItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(
                          Icons.info,
                          color: Colors.black38,
                        ),
                        SizedBox(
                          child: Text('About'),
                          width: 64,
                        )
                      ],
                    ),
                    value: 'about',
                  )
                ]),
          ],
        ),
        body: Align(
            alignment: Alignment(0, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildDialPad(),
                      )),
                ])));
  }
}
