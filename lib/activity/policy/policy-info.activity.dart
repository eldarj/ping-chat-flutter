import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PolicyInfoActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          leading: CloseButton(onPressed: () {
            Navigator.pop(context);
          }),
          actions: [
            Container(
                margin: EdgeInsets.only(right: 20),
                child: Center(child: Text('Last updated April 23 2021',
                  style: TextStyle(color: Colors.grey.shade500),)))
          ],
          backgroundColor: Colors.white
      ),
      body: Builder(builder: (context) {
        return Container(
            color: Colors.white,
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: ListView(
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 25, right: 25, top: 5, bottom: 35),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Use of information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Icon(Icons.info_rounded, color: Colors.grey.shade400)
                                  )
                                ]
                            ),
                          ),
                          Text('We may use your information in other ways for which we provide specific notice at the time of collection.\n'),
                          Text('No information will be externally used or exposed.'),
                          Container(
                              margin: EdgeInsets.only(top: 20, bottom: 20),
                              child: Text('Publicly viewable information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                          Text('No sensitive information will be visible neither externally nor internally, only on the '
                              'user\'s side and user\'s contacts side.'),
                          Divider(height: 50),
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Media', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Icon(Icons.perm_media_rounded, color: Colors.grey.shade400)
                                  )
                                ]
                            ),
                          ),
                          Text('Only media that you provide publicly, using the media settings, will be viewable by '
                              'the users.\n\nPlease, check out more under your profile and media settings.\n'),
                          Container(
                              margin: EdgeInsets.only(top: 20, bottom: 20),
                              child: Text('Personal data protection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                          Text('Ping takes the security of your personal data very seriously.\n\nPing will make the best '
                              'effort to secure any personal data, while storing it as well as during the transit using '
                              'encryption such as Transport Layer Security, SSL and encryption.\n\n'),
                          Text('When you use some Ping services and applications, we strongly advise to make sure what '
                              'information you publicly share, any data that is set to public, can be viewed by '
                              'end users.\n\nWhich for Ping can not restrict to read, collect or use in any way.'),
                        ])),
                        Container(
                            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                            color: Colors.grey.shade50,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                                margin: EdgeInsets.only(bottom: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Need help?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Icon(Icons.question_answer, color: Colors.grey.shade400)
                                    )
                                  ]
                                )),
                            Text('If any clarification or help needed, please contact us at policy@ping.com')
                          ])
                        ),
                    ]
                )
            )
        );
      }),
    );
  }
}
