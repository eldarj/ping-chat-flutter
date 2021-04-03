import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/single-chat/chat.activity.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/action-button.component.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;

class SingleContactActivity extends StatefulWidget {
  final int userId;

  final ClientDto peer;

  final String contactName;

  final int contactBindingId;

  final String myContactName;

  final String statusLabel;

  final bool favorite;

  const SingleContactActivity({ Key key,
    this.myContactName, this.statusLabel,
    this.peer, this.userId, this.contactName, this.favorite, this.contactBindingId }) : super(key: key);

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

  bool favorite;

  bool isFavorite() => favorite ?? widget.favorite;

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
                  child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100))
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
                    ActionButton(
                      icon: Icons.chat,
                      fillColor: CompanyColor.bluePrimary,
                      onPressed: () async {
                        NavigatorUtil.push(context, ChatActivity(
                            myContactName: widget.myContactName, peer: widget.peer, peerContactName: widget.contactName,
                            statusLabel: widget.statusLabel, contactBindingId: widget.contactBindingId));
                      },
                    ),
                    ActionButton(
                      icon: Icons.phone,
                      fillColor: CompanyColor.bluePrimary,
                      onPressed: () async {
                        await Future.delayed(Duration(milliseconds: 250));
                        NavigatorUtil.push(context, new CallScreenWidget(
                          target: widget.peer.fullPhoneNumber,
                          contactName: widget.contactName,
                          fullPhoneNumber: widget.peer.fullPhoneNumber,
                          profileImageWidget: profileImageWidget,
                          direction: 'OUTGOING',
                        ));
                      },
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
                    buildDrawerItem(context, 'Phonenumber',
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
                    buildSectionHeader('Shared media', linkWidget: TextButton(
                      onPressed: () {
                        NavigatorUtil.push(context, ContactSharedActivity(
                            peer: widget.peer,
                            picturesPath: picturesPath,
                            peerContactName: widget.contactName,
                            contactBindingId: widget.contactBindingId));
                      },
                      child: Text('See more', style: TextStyle(color: CompanyColor.bluePrimary)),
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
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                          onPressed: () => doUpdateFavourites()
                              .then(onUpdateFavouritesSuccess, onError: onUpdateFavouritesError),
                          child: Row(
                              children: [
                                Container(
                                    padding: EdgeInsets.all(7.5),
                                    margin: EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Icon(isFavorite() ? Icons.star_border : Icons.star,
                                        color: Colors.yellow.shade700, size: 17)),
                                Text(isFavorite() ? 'Remove from favourites' : 'Add to favourites',
                                    style: TextStyle(color: Colors.grey.shade700))
                              ]
                          )),
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
                      TextButton(onPressed: () {},
                          child: Row(children: [
                            Container(
                                padding: EdgeInsets.all(7.5),
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey.shade50,
                                ),
                                child: Icon(Icons.delete, color: Colors.red, size: 17)),
                            Text('Delete contact', style: TextStyle(color: CompanyColor.red))
                          ])),
                      TextButton(onPressed: () {},
                          child: Row(children: [
                            Container(
                                padding: EdgeInsets.only(right: 6.5, left: 8.5, top: 7.5, bottom: 7.5),
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey.shade50,
                                ),
                                child: Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 17)),
                            Text('Delete all messages', style: TextStyle(color: CompanyColor.red))
                          ])),
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
        children: [
          Row(children: [
            Container(height: 300, width: DEVICE_MEDIA_SIZE.width, color: CompanyColor.bluePrimary)
          ]),
          Container(
            height: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(bottom: maximizeProfilePhoto ? 0 : 0),
                  height: maximizeProfilePhoto ? 350 : 150,
                  width: maximizeProfilePhoto ? DEVICE_MEDIA_SIZE.width : 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: maximizeProfilePhoto ? 0 : 3),
                    borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 100),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(maximizeProfilePhoto ? 0 : 100),
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
          children: [
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
          height: nodes.length > 4 ? 300 : 150, width: DEVICE_MEDIA_SIZE.width,
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
        _w = Container(child: Text("You don't have any shared media", style: TextStyle(color: Colors.grey)));
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
            : Text('TODO: fixme 1'),
      );
    } else if (node.nodeType == 'RECORDING' || node.nodeType == 'MEDIA' || node.nodeType == 'FILE') {
      _w = DSMedia(node: node, gridHorizontalSize: 3, picturesPath: picturesPath);
    } else {
      _w = Center(child: Text('Unrecognized media.'));
    }

    return Container(
        child: fileExists ? _w
            : Text('TODO: fixme 4'));
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

  Future<bool> doUpdateFavourites() async {
    String url = '/api/contacts/${widget.peer.id}/favourite';

    http.Response response = await HttpClientService.post(url, body: !isFavorite());

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return !isFavorite();
  }

  onUpdateFavouritesSuccess(status) {
    setState(() {
      favorite = status;
    });

    scaffold.removeCurrentSnackBar();
    if (isFavorite()) {
      scaffold.showSnackBar(SnackBarsComponent.success('${widget.contactName} added to favourites.'));
    } else {
      scaffold.showSnackBar(SnackBarsComponent.info('${widget.contactName} removed from favourites.'));
    }
  }

  onUpdateFavouritesError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Something went wrong, please try again.'
    ));
  }
}
