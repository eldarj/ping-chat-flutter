import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageUploadActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ProfileImageUploadActivityState();
}

class ProfileImageUploadActivityState extends BaseState<ProfileImageUploadActivity> {
  bool isLoadingSaveButton = false;
  bool isSaveButtonSuccess = false;
  bool displayUploadedImage = false;

  String imagePath;
  File imageFile;

  chooseImage() async {
    ImagePicker imagePicker = new ImagePicker();

    PickedFile pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    imagePath = pickedFile.path;
    imageFile = File(pickedFile.path);

    setState(() {
      displayLoader = true;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      displayLoader = false;
      displayUploadedImage = true;
      isSaveButtonSuccess = false;
    });
  }

  initialize() async {
    setState(() {
      displayLoader = true;
    });
    chooseImage();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget render() {
    return buildActivityContent();
  }

  Widget buildActivityContent() {
    Widget content = Container(
        color: Color(0xEE0000000),
        child: Center(child: Spinner())
    );

    var screenSize = MediaQuery.of(context).size;

    if (!displayLoader) {
      if (displayUploadedImage) {
        content = Stack(alignment: AlignmentDirectional.bottomCenter, children: [
          Container(
            height: screenSize.height,
            width: screenSize.width,
            padding: EdgeInsets.all(50),
            color: Color(0xEE0000000),
            child: Image.file(
              imageFile, fit: BoxFit.contain,
            ),
          ),
          buildOptionsBar()
        ]);
      } else {
        content = Container();
      }
    }

    return content;
  }

  Widget buildOptionsBar() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, bottom: 50),
      child: ButtonTheme(
        buttonColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                  color: Colors.grey,
                  colorBrightness: Brightness.dark,
                  onPressed: isLoadingSaveButton || isSaveButtonSuccess ? null : () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel')
              ),
              ButtonBar(
                buttonPadding: EdgeInsets.all(0),
                buttonHeight: 60,
                children: [
                  RaisedButton(
                    onPressed: isLoadingSaveButton || isSaveButtonSuccess ? null : chooseImage,
                    child: Icon(Icons.photo_library),
                  ),
                ],
              ),
              buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildSaveButton() {
    return RaisedButton(
        color: Colors.blueGrey,
        colorBrightness: Brightness.dark,
        onPressed: isLoadingSaveButton || isSaveButtonSuccess ? null : () async {
          setState(() {
            isLoadingSaveButton = true;
          });
          doUploadProfileImage().then(onUploadProfileImageSuccess, onError: onUploadProfileImageError);
        },
        child: isLoadingSaveButton ? Container(
            height: 20, width: 20,
            child: Spinner()
        ) : Container(margin: EdgeInsets.only(right: 10),
            child: isSaveButtonSuccess ? Container(
                child: Icon(Icons.check_circle, color: Colors.green)
            ) : Text('Save'))
    );
  }

  Future<String> doUploadProfileImage() async {
    var user = await UserService.getUser();
    var response = await HttpClientService.postMultipartFile('/api/users/${user.id}/profile-image', imagePath, imageFile);

    if (response.statusCode != 200) {
      throw new Exception();
    }

    return await response.stream.bytesToString();
  }

  void onUploadProfileImageSuccess(savedProfileImagePath) async {
    UserService.setUserProfileImagePath(savedProfileImagePath);

    setState(() {
      isLoadingSaveButton = false;
      isSaveButtonSuccess = true;
    });

    Navigator.pop(context, savedProfileImagePath);
  }

  void onUploadProfileImageError(error) {
    print(error);
    setState(() {
      isLoadingSaveButton = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(duration: Duration(seconds: 2), actionOnPressed: () async {
      setState(() {
        isLoadingSaveButton = true;
      });

      doUploadProfileImage().then(onUploadProfileImageSuccess, onError: onUploadProfileImageError);
    }));
  }
}
