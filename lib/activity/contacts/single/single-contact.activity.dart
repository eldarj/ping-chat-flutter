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
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/action-button.component.dart';
import 'package:flutterping/shared/component/country-icon.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SingleContactActivity extends StatefulWidget {
  final int userId;

  final ClientDto peer;

  final String contactName;

  final String contactPhoneNumber;

  final int contactBindingId;

  final String myContactName;

  final String statusLabel;

  final bool favorite;

  final bool isContactAdded;

  const SingleContactActivity({ Key key,
    this.myContactName, this.statusLabel,
    this.peer, this.userId, this.contactName, this.favorite,
    this.contactBindingId, this.contactPhoneNumber, this.isContactAdded }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SingleContactActivityState(
      contactName: contactName,
      isContactAdded: isContactAdded
  );
}

class SingleContactActivityState extends BaseState<SingleContactActivity> {
  StateSetter backgroundsModalSetState;

  String contactName;

  ScrollController scrollController = new ScrollController();

  List<DSNodeDto> nodes = new List();

  ContactDto contact;

  Widget profileImageWidget;

  bool maximizeProfilePhoto = true;

  bool displaySharedDataSpaceLoader = true;

  String picturesPath;

  bool favorite;

  bool isFavouriteButtonLoaing = false;

  bool isFavorite() => favorite ?? widget.favorite;

  TextEditingController contactNameController;
  bool displayContactNameButtonLoader = false;
  bool isContactNameValid = true;
  String contactNameValidationMessage = '';

  List backgrounds = [];
  bool displayBackgroundsLoader = true;
  bool displayBackgroundsButton = true;
  int backgroundLoaderIndex;

  bool displayDeleteContactLoader = false;

  bool isContactAdded = true;
  bool displayAddContactLoader = false;

  SingleContactActivityState({ this.contactName, this.isContactAdded }) {
    this.contactNameController = TextEditingController(text: contactName);
  }

  init() async {
    picturesPath = await new StorageIOService().getPicturesPath();

    if (widget.peer != null) {
      doGetContactData();
      doGetSharedData().then(onGetSharedDataSuccess, onError: onGetSharedDataError);
    }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doGetBackgrounds().then(onGetBackgroundsSuccess, onError: onGetBackgroundsError);
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
    contactNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar.getBackAppBar(getScaffoldContext, titleText: contactName),
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

        if (widget.peer?.profileImagePath != null) {
          profileImageWidget = CachedNetworkImage(imageUrl: widget.peer.profileImagePath, fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  margin: EdgeInsets.all(15),
                  child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)
              )
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
              widget.peer != null ? Container(
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
                  ])) : Container(),
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      boxShadow: [Shadows.bottomShadow()]
                  ),
                  child: buildTwoColumns([
                    buildDrawerItem(context, 'Phone number',
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
                        labelDescription: widget.contactPhoneNumber),
                  ], [
                    widget.peer != null ? buildDrawerItem(context, widget.peer.countryCode.countryName,
                        CountryIconComponent.buildCountryIcon(
                            widget.peer.countryCode.countryName, height: 15, width: 15
                        )) : Container(),
                  ])
              ),
              buildSharedMediaSection(),
              buildDetailsSection(),
              buildFavouritesSection(),
              buildDeleteSection(),
              buildNotRegisteredUserSection(),
              Container(height: 50),
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

  Widget buildDetailsSection() {
    Widget w = Container();

    if (contact != null) {
      w = Container(
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
              buildBackgroundButton(),
              displayBackgroundsButton ? buildChangeContactNameButton() : Container(),
            ]),
      );
    }

    return w;
  }

  buildBackgroundButton() {
    return TextButton(
        onPressed: () {
          showCustomModalBottomSheet(context: context,
              containerWidget: (_, animation, child) => FloatingModal(
                child: child,
                maxHeight: DEVICE_MEDIA_SIZE.height - 100,
              ),
              builder: buildBackgroundModal
          );
        },
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    padding: EdgeInsets.all(7.5),
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade50,
                    ),
                    child: Icon(Icons.image_outlined,
                        color: Colors.green, size: 17)),
                Text('Chat background',
                    style: TextStyle(color: Colors.grey.shade700)),
              ]),
            ]
        ));
  }

  Widget buildBackgroundModal(BuildContext context)  {
    return StatefulBuilder(
        builder: (context, setState) {
          backgroundsModalSetState = setState;
          return Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Column(children: [
                Container(
                  margin: EdgeInsets.only(left: 20, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(margin: EdgeInsets.only(right: 10),
                              width: 45, height: 45,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  color: Colors.grey.shade400
                              ),
                              child: Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 20)),
                          Container(child: Text('Chat background', style: TextStyle(color: Colors.grey.shade700))),
                        ],
                      ),
                      CloseButton(onPressed: () async {
                        Navigator.of(context).pop();
                        backgroundLoaderIndex = null;
                      })
                    ],
                  ),
                ),
                Divider(height: 25, thickness: 1),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(bottom: 20),
                    margin: EdgeInsets.only(left: 20, right: 20),
                    child: displayBackgroundsLoader ? Center(child: Spinner()) : Align(
                      child: Opacity(
                        opacity: backgroundLoaderIndex != null ? 0.5 : 1,
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: 2),
                          itemCount: backgrounds.length,
                          itemBuilder: (context, index) {
                            var background = API_BASE_URL + '/files/chats/' + backgrounds[index];
                            var backgroundWidth = DEVICE_MEDIA_SIZE.width / 2 - 50;
                            return Align(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      doUpdateBackgroundImage(setState, index).then(onUpdateBackgroundSuccess, onError: onUpdateBackgroundError);
                                    },
                                    child: Container(
                                        padding: EdgeInsets.all(5),
                                        height: backgroundWidth * 3,
                                        width: backgroundWidth,
                                        decoration: BoxDecoration(
                                            color: contact.backgroundImagePath == backgrounds[index]
                                                ? CompanyColor.bluePrimary
                                                : Colors.white,
                                            border: Border.all(color: contact.backgroundImagePath == backgrounds[index]
                                                ? CompanyColor.bluePrimary
                                                : Colors.grey.shade100),
                                            borderRadius: BorderRadius.circular(5),
                                            boxShadow: [BoxShadow(color: Colors.grey.shade50,
                                              offset: Offset.fromDirection(1, 0.7),
                                              blurRadius: 5, spreadRadius: 5,
                                            )]
                                        ),
                                        child: CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          imageUrl: background,
                                        )
                                    ),
                                  ),
                                  backgroundLoaderIndex == index ? Spinner(size: 45) : Container(),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
              ])
          );
        }
    );
  }

  buildChangeContactNameButton() {
    return TextButton(
        onPressed: () {
          showCustomModalBottomSheet(context: context,
              containerWidget: (_, animation, child) => FloatingModal(
                child: child,
                maxHeight: DEVICE_MEDIA_SIZE.height - 100,
              ),
              builder: (context) {
                return StatefulBuilder(
                    builder: (context, setState) {
                      return Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Column(children: [
                            Container(
                              margin: EdgeInsets.only(left: 20, right: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(margin: EdgeInsets.only(right: 10),
                                          width: 45, height: 45,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(50.0),
                                              color: Colors.grey.shade400
                                          ),
                                          child: Icon(Icons.edit, color: Colors.grey.shade300, size: 20)),
                                      Container(child: Text('Change contact name', style: TextStyle(color: Colors.grey.shade700))),
                                    ],
                                  ),
                                  CloseButton(onPressed: () async {
                                    Navigator.of(context).pop();
                                    await Future.delayed(Duration(seconds: 1));
                                    this.isContactNameValid = true;
                                    this.contactNameValidationMessage = '';
                                    this.contactNameController.text = contact.contactName;
                                    this.displayContactNameButtonLoader = false;
                                  })
                                ],
                              ),
                            ),
                            Divider(height: 25, thickness: 1),
                            Container(
                              margin: EdgeInsets.only(left: 20, right: 20),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                TextField(
                                  controller: contactNameController,
                                  onChanged: (value) {
                                    var valid = value.length >= 3;
                                    setState(() {
                                      this.isContactNameValid = valid;
                                      this.contactNameValidationMessage = valid ? '' : 'Name has to contain at least 3 characters';
                                    });
                                  },
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      hintText: 'Name',
                                      labelText: 'Name',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(15)),
                                ),
                                Container(
                                    margin: EdgeInsets.only(top: 5, left: 2),
                                    child: Text(contactNameValidationMessage,
                                        style: TextStyle(color: CompanyColor.red))
                                ),
                                Container(
                                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    GradientButton(
                                      child: displayContactNameButtonLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Save'),
                                      onPressed: isContactNameValid && !displayContactNameButtonLoader ?
                                          () => doUpdateContactName(setState).then(onUpdateContactNameSuccess, onError: onUpdateContactNameError) : null,
                                    )
                                  ]),
                                )
                              ]),
                            )
                          ])
                      );
                    }
                );
              });
        },
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    padding: EdgeInsets.all(7.5),
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade50,
                    ),
                    child: Icon(Icons.edit,
                        color: Colors.blue, size: 17)),
                Text('Change contact name',
                    style: TextStyle(color: Colors.grey.shade700)),
              ]),
            ]
        ));
  }

  Widget buildDeleteSection() {
    Widget w = Container();

    if (widget.peer != null && contact != null) {
      w = Container(
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
                  onPressed: () {
                    doDeleteContact().then(onDeleteSuccess, onError: onDeleteError);
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                              padding: EdgeInsets.all(7.5),
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.shade50,
                              ),
                              child: Icon(Icons.delete, color: Colors.red, size: 17)),
                          Text('Delete contact', style: TextStyle(color: CompanyColor.red)),
                        ]),
                        displayDeleteContactLoader ? Spinner(size: 20) : Container()
                      ])),
              widget.peer != null ? TextButton(onPressed: () {},
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
                  ])) : Container(),
            ]),
      );
    }

    return w;
  }

  Widget buildFavouritesSection() {
    Widget w = Container();

    if (widget.peer != null && contact != null) {
      w = Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
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
                              style: TextStyle(color: Colors.grey.shade700)),
                        ]),
                        isFavouriteButtonLoaing ? Spinner(size: 20) : Container()
                      ]
                  )),
            ]),
      );
    }

    return w;
  }

  Widget buildNotRegisteredUserSection() {
    Widget w = Container();

    if (widget.peer == null) {
      w = Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            boxShadow: [Shadows.bottomShadow()]
        ),
        child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(left: 5, right: 5),
            child : Text('This contact isn\'t a registered Ping user.', style: TextStyle(
                color: Colors.grey
            ))),
      );
    }

    return w;
  }

  Widget buildSharedMediaSection() {
    return widget.peer != null ? Container(
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
            child: displaySharedDataSpaceLoader
                ? Spinner(size: 20) : nodes != null && nodes.length > 0
                ? Text('See more', style: TextStyle(color: CompanyColor.bluePrimary))
                : Container(),
          )),
          buildDataSpaceListView(),
        ])) : Container();
  }

  Widget buildContactProfileSection() {
    Widget w;
    if (widget.peer != null) {
      w = Column(children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Row(children: [
              contact?.backgroundImagePath != null ? Container(height: 300, width: DEVICE_MEDIA_SIZE.width, child: CachedNetworkImage(
                imageUrl: API_BASE_URL + '/files/chats/' + contact.backgroundImagePath, fit: BoxFit.cover,
              )) : Container(height: 300, width: DEVICE_MEDIA_SIZE.width, color: CompanyColor.bluePrimary),
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
                      child: profileImageWidget ?? Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ]);
    } else {
      w = Column(
        children: [
          Container(
            width: 150,
            height: 150,
            margin: EdgeInsets.only(top: 10),
            child: ClipRRect(borderRadius: BorderRadius.circular(100),
              child: Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH, fit: BoxFit.cover),
            ),
          ),
        ],
      );
    }
    return w;
  }

  Widget buildSectionHeader(title, { icon, linkWidget }) {
    return Container(
        padding: EdgeInsets.only(top: 10, left: 10),
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
        _w = Container(height: 15,
            child: Text("You don't have any shared media", style: TextStyle(color: Colors.grey)));
      }
    } else {
      _w = Container(height: 15);
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

  void doGetContactData() async {
    String url = '/api/contacts/${widget.userId}/search/${widget.peer.id}';

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    if (response.bodyBytes != null && response.bodyBytes.length > 0) {
      setState(() {
        contact = ContactDto.fromJson(response.decode());
      });
    }
  }

  Future doGetSharedData() async {
    String url = '/api/data-space/shared'
        '?userId=' + widget.userId.toString() +
        '&contactId=' + widget.peer.id.toString() +
        '&nodesCount=10';

    http.Response response = await HttpClientService.get(url);

    await Future.delayed(Duration(seconds: 1));

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
    setState(() {
      isFavouriteButtonLoaing = true;
    });

    String url = '/api/contacts/${contact.id}/favourite';

    http.Response response = await HttpClientService.post(url, body: !isFavorite());

    if(response.statusCode != 200) {
      throw new Exception();
    }

    await Future.delayed(Duration(seconds: 1));

    return !isFavorite();
  }

  onUpdateFavouritesSuccess(favouriteStatus) {
    setState(() {
      favorite = favouriteStatus;
      isFavouriteButtonLoaing = false;
    });

    scaffold.removeCurrentSnackBar();
    if (isFavorite()) {
      scaffold.showSnackBar(SnackBarsComponent.success('${widget.contactName} added to favourites.'));
    } else {
      scaffold.showSnackBar(SnackBarsComponent.info('${widget.contactName} removed from favourites.'));
    }

    contactPublisher.emitFavouritesUpdate(contact.contactBindingId, favouriteStatus);
  }

  onUpdateFavouritesError(error) {
    setState(() {
      isFavouriteButtonLoaing = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Something went wrong, please try again.'
    ));
  }

  // UPDATE CONTACT NAME
  Future<String> doUpdateContactName(StateSetter setState) async {
    setState(() {
      displayContactNameButtonLoader = true;
    });

    String url = '/api/contacts/${contact.id}/name';

    http.Response response = await HttpClientService.post(url, body: contactNameController.text);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    await Future.delayed(Duration(seconds: 1));

    return contactNameController.text;
  }

  void onUpdateContactNameSuccess(String name) async {
    scaffold.showSnackBar(SnackBarsComponent.success('Updated name', duration: Duration(seconds: 4)));

    setState(() {
      contactName = name;
      contact.contactName = name;
    });

    this.isContactNameValid = true;
    this.contactNameValidationMessage = '';
    this.contactNameController.text = contact.contactName;
    this.displayContactNameButtonLoader = false;

    Navigator.of(context).pop();
    contactPublisher.emitNameUpdate(contact.contactBindingId, contact.contactUser.id, name);
  }

  void onUpdateContactNameError(error) async {
    scaffold.showSnackBar(SnackBarsComponent.success('not so much', duration: Duration(seconds: 4)));

    this.isContactNameValid = true;
    this.contactNameValidationMessage = '';
    this.contactNameController.text = contact.contactName;
    this.displayContactNameButtonLoader = false;

    Navigator.of(context).pop();
  }

  // UPDATE BACKGROUND IMAGE
  Future<String> doUpdateBackgroundImage(StateSetter setState, int index) async {
    setState(() {
      backgroundLoaderIndex = index;
    });

    String url = '/api/contacts/${contact.id}/background';

    http.Response response = await HttpClientService.post(url, body: backgrounds[index]);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return backgrounds[index];
  }

  void onUpdateBackgroundSuccess(String background) async {
    scaffold.showSnackBar(SnackBarsComponent.success('Updated background', duration: Duration(seconds: 4)));

    setState(() {
      contact.backgroundImagePath = background;
    });

    backgroundLoaderIndex = null;
    Navigator.of(context).pop();

    contactPublisher.emitBackgroundUpdate(contact.contactBindingId, background);
  }

  void onUpdateBackgroundError(error) async {
    scaffold.showSnackBar(SnackBarsComponent.success('not so much', duration: Duration(seconds: 4)));

    backgroundLoaderIndex = null;
    Navigator.of(context).pop();
  }

  // GET BACKGROUNDS
  Future<List> doGetBackgrounds() async {
    http.Response response = await HttpClientService.get('/api/chat/backgrounds', cacheKey: "backgroundsImages");

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return response.decode();
  }

  void onGetBackgroundsSuccess(List backgrounds) {
    this.backgrounds = backgrounds;

    displayBackgroundsLoader = false;
    if (backgroundsModalSetState != null) {
      backgroundsModalSetState(() {
        displayBackgroundsLoader = false;
      });
    }
  }

  void onGetBackgroundsError(error) {
    print(error);

    setState(() {
      displayBackgroundsButton = false;
    });
  }

  // Delete contact
  Future<String> doDeleteContact() async {
    setState(() {
      displayDeleteContactLoader = true;
    });

    String url = '/api/contacts/${contact.id}/delete'
        '?contactBindingId=${contact.contactBindingId}'
        '&userId=${widget.userId}';

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return contact.contactName;
  }

  void onDeleteSuccess(String contactName) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.success('$contactName deleted'));
  }

  void onDeleteError(error) {
    print(error);

    setState(() {
      displayDeleteContactLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
      content: 'Something went wrong, please try again', duration: Duration(seconds: 2)
    ));
  }
}
