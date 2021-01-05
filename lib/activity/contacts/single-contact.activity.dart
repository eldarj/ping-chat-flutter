import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/calls/dialpad.activity.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/activity/profile/profile-image-upload/profile-image-upload.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class SingleContactActivity extends StatefulWidget {
  final int userId;

  final ClientDto peer;

  final String contactName;

  final int contactBindingId;

  final bool favorite;

  const SingleContactActivity({ Key key, this.peer, this.userId, this.contactName, this.favorite, this.contactBindingId }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SingleContactActivityState();
}

class SingleContactActivityState extends BaseState<SingleContactActivity> {
  ScrollController scrollController = new ScrollController();

  List<DSNodeDto> nodes = new List();

  Widget profileImageWidget;

  bool maximizeProfilePhoto = true;

  bool displaySharedDataSpaceLoader = true;

  String picturesPath;

  init() async {
    picturesPath = await new StorageIOService().getPicturesPath();

    doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);

    scrollController.addListener(() async {
      if (scrollController.position.pixels < 50 && maximizeProfilePhoto == false) {
        setState(() {
          maximizeProfilePhoto = true;
        });
      } else if (scrollController.position.pixels > 50 && maximizeProfilePhoto == true) {
        setState(() {
          maximizeProfilePhoto = false;
        });
      }
    });
  }

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleText: widget.contactName),
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return Container(
          child: buildActivityContent(),
        );
      }),
    );
  }

  Widget buildActivityContent() {
    Widget _w = Center(child: Spinner());
    if (!displayLoader) {
      if (!isError) {

        if (widget.peer.profileImagePath != null) {
          profileImageWidget = CachedNetworkImage(imageUrl: widget.peer.profileImagePath, fit: BoxFit.cover,
            placeholder: (context, url) => Container(
                margin: EdgeInsets.all(15),
                child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)),
          );
        }

        _w = Container(
            child: ListView(controller: scrollController, children: [
              Container(
                  padding: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white
                  ),
                  child: buildContactProfileSection()),
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 25),
                  color: Colors.white,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                        margin: EdgeInsets.only(right: 25),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CompanyColor.bluePrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: GestureDetector(
                            onTap: () {},
                            child: Container(child: Icon(Icons.chat, color: Colors.white))
                        )
                    ),
                    Container(
                        margin: EdgeInsets.only(left: 25),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: CompanyColor.bluePrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: GestureDetector(
                            onTap: () {
                              NavigatorUtil.push(context, new CallScreenWidget(
                                target: '1004',
                                contactName: widget.contactName,
                                fullPhoneNumber: widget.peer.fullPhoneNumber,
                                profileImageWidget: profileImageWidget,
                                direction: 'OUTGOING',
                              ));
                            },
                            child: Container(child: Icon(Icons.phone, color: Colors.white))
                        )
                    ),
                  ])),
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      boxShadow: [Shadows.bottomShadow()]
                  ),
                  child: buildTwoColumns([
                    buildDrawerItem(context, 'Broj telefona',
                        Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade400,
                            ),
                            child: Container(
                                width: 35, height: 35,
                                child: Icon(Icons.phone_iphone, size: 20, color: Colors.white)
                            )),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15),
                        labelDescription: widget.peer.fullPhoneNumber),
                  ], [
                    buildDrawerItem(context, widget.peer.countryCode.countryName,
                        CountryIconComponent.buildCountryIcon(
                            widget.peer.countryCode.countryName, height: 15, width: 15
                        )),
                  ])
              ),
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      boxShadow: [Shadows.bottomShadow()]
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    buildSectionHeader('Djeljeni medij', linkWidget: FlatButton(
                      onPressed: () {
                        NavigatorUtil.push(context, ContactSharedActivity(
                            peer: widget.peer,
                            picturesPath: picturesPath,
                            peerContactName: widget.contactName,
                            contactBindingId: widget.contactBindingId));
                      },
                      child: Text('Pogledaj sve', style: TextStyle(color: CompanyColor.bluePrimary)),
                    )),
                    buildDataSpaceListView(),
                  ])),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FlatButton(onPressed: () {}, child: Row(children: [
                    Container(
                        margin: EdgeInsets.only(right: 10),
                        child: Icon(Icons.photo_library, color: Colors.grey.shade700)),
                    Text('Pozadina', style: TextStyle(color: Colors.grey.shade700))
                  ]))
                ]),
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      !widget.favorite ? FlatButton(onPressed: () {}, child: Row(
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Icon(Icons.star, color: Colors.yellow.shade700)),
                          Text('Dodaj u omiljene', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      )) : FlatButton(onPressed: () {}, child: Row(
                        children: <Widget>[
                          Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Icon(Icons.star_border, color: Colors.yellow.shade700)),
                          Text('Ukloni iz omiljenih', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ))
                    ]),
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).backgroundColor,
                    boxShadow: [Shadows.bottomShadow()]
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlatButton(onPressed: () {}, child: Text('Izbriši kontakt', style: TextStyle(color: CompanyColor.red))),
                      FlatButton(onPressed: () {}, child: Text('Blokiraj kontakt', style: TextStyle(color: CompanyColor.red))),
                      FlatButton(onPressed: () {}, child: Text('Izbriši sve poruke', style: TextStyle(color: CompanyColor.red))),
                    ]),
              )
            ])
        );
      } else {
        _w = ErrorComponent.build(actionOnPressed: () async {
          scaffold.removeCurrentSnackBar();
          setState(() {
            displayLoader = true;
            isError = false;
          });

          // doGetProfileData().then(onGetProfileDataSuccess, onError: onGetProfileDataError);
        });
      }
    }

    return _w;
  }

  Widget buildContactProfileSection() {
    return Column(children: [
      Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Row(children: [
            Container(height: 250, width: DEVICE_MEDIA_SIZE.width, color: CompanyColor.bluePrimary)
          ]),
          Container(
            height: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(bottom: maximizeProfilePhoto ? 0 : 0),
                  height: maximizeProfilePhoto ? 350 : 200,
                  width: maximizeProfilePhoto ? DEVICE_MEDIA_SIZE.width : 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: maximizeProfilePhoto ? 0 : 3),
                    borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 32.5),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 30),
                    child: profileImageWidget ?? Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget buildSectionHeader(title, { icon, linkWidget }) {
    return Container(
        padding: EdgeInsets.only(top: 10, left: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(children: [
              Container(
                  margin: EdgeInsets.only(right: 5),
                  child: icon != null ? Icon(icon, size: 25) : Container()),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ]),
            linkWidget != null ? linkWidget : Container()
          ],
        ));
  }

  Widget buildTwoColumns(leftChildren, rightChildren) {
    return Wrap(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: leftChildren)
            ),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rightChildren
                )
            )
          ]
      )
    ]);
  }

  buildDataSpaceListView() {
    Widget _w;

    if (!displaySharedDataSpaceLoader) {
      if (nodes != null && nodes.length > 0) {
        _w = Container(
          height: nodes.length > 4 ? 250 : 150, width: DEVICE_MEDIA_SIZE.width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 2.5, mainAxisSpacing: 2.5, crossAxisCount: nodes.length > 4 ? 2 : 1),
              itemCount: nodes.length, itemBuilder: (context, index) {
            var node = nodes[index];
            return buildSingleNode(node);
          }),
        );
      } else {
        _w = Container(child: Text('Nemate podataka', style: TextStyle(color: Colors.grey)));
      }
    } else {
      _w = Container(margin: EdgeInsets.only(left: 5), child: Spinner(size: 25));
    }

    return Container(
        margin: EdgeInsets.only(left: 15, bottom: 15),
        child: _w);
  }

  buildSingleNode(DSNodeDto node) {
    bool fileExists;
    String filePath;
    filePath = picturesPath + '/' + node.nodeName;

    fileExists = File(filePath).existsSync();

    Widget _w;

    if (node.nodeType == 'IMAGE') {
      _w = GestureDetector(
        onTap: () async {
          var result = await NavigatorUtil.push(context,
              ImageViewerActivity(
                  nodeId: node.id,
                  sender: widget.contactName,
                  timestamp: node.createdTimestamp,
                  file: File(filePath)));

          if (result != null && result['deleted'] == true) {
            setState(() {
              nodes.removeWhere((element) => element.id == node.id);
            });
          }
        },
        child: fileExists ? Image.file(File(filePath), fit: BoxFit.cover)
            : Text('TODO: fixme'),
      );
    } else if (node.nodeType == 'RECORDING' || node.nodeType == 'MEDIA') {
      _w = DSMedia(node: node, gridHorizontalSize: 5, picturesPath: picturesPath);
    } else {
      _w = Center(child: Text('Unrecognized media.'));
    }

    return Container(
        child: fileExists ? _w
            : Text('TODO: fixme'));
  }

  Future doGetSharedData() async {
    String url = '/api/data-space/shared'
        '?userId=' + widget.userId.toString() +
        '&contactId=' + widget.peer.id.toString() +
        '&nodesCount=10';

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return List<DSNodeDto>.from(response.decode().map((e) => DSNodeDto.fromJson(e))).toList();
  }

  void onGetSharedDataSuccess(nodes) async {
    print(nodes.length.toString());
    this.nodes = nodes;

    setState(() {
      displaySharedDataSpaceLoader = false;
    });
  }

  void onGetSharedDataError(Object error) {
    print(error);
    setState(() {
      displaySharedDataSpaceLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displaySharedDataSpaceLoader = true;
      });

      doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);
    }));
  }
}
