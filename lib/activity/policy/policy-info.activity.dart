import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PolicyInfoActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          leading: FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.close),
          ),
          actions: [
            Container(
                margin: EdgeInsets.only(right: 20),
                child: Center(child: Text('Last updated 2.4.2021',
                  style: TextStyle(fontSize: 12, color: Colors.grey),)))
          ],
          backgroundColor: Colors.white),
      body: Builder(builder: (context) {
        return Container(
            color: Colors.white,
            child: Container(
                margin: EdgeInsets.only(top: 10, bottom: 0, left: 50, right: 50),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: ListView(
                    children: [
                      Container(
                          margin: EdgeInsets.only(top: 20, bottom: 20),
                          child: Text('Use of information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Text('We may use your information in other ways for which we provide specific notice at the time of collection.\n\n'),
                      Text('No information will be externally used or exposed.'),
                      Container(
                          margin: EdgeInsets.only(top: 20, bottom: 20),
                          child: Text('Publicly viewable information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Text('No sensitive information will be visible neither externally nor internally, only on the '
                          'user\'s side and user\'s contacts side.'),
                      Container(
                          margin: EdgeInsets.only(top: 20, bottom: 20),
                          child: Text('Media', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Text('Only media that you provide publicly, using the media settings, will be viewable by '
                          'the users.\n\n\nPlease, check out more under your profile and media settings.\n'),
                      Container(
                          margin: EdgeInsets.only(top: 20, bottom: 20),
                          child: Text('Personal data protection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      Text('Ping takes the security of your personal data very seriously.\n\n\nPing will make the best '
                          'effort to secure any personal data, while storing it as well as during the transit using '
                          'encryption such as Transport Layer Security, SSL and encryption.\n\n'),
                      Text('When you use some Ping services and applications, we strongly advise to make sure what '
                          'information you publicly share, any data that is set to public, can be viewed by '
                          'end users.\n\nWhich for Ping can not restrict to read, collect or use in any way.'),
                      Container(
                          margin: EdgeInsets.only(top: 30, bottom: 20),
                          child: Text('Need help?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      Text('If any clarification or help needed, please contact us at policy@ping.com\n\n\n')
                    ]
                )
            )
        );
      }),
    );
  }
}
