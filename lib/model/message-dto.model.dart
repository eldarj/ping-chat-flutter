import 'package:filesize/filesize.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/reply-dto.model.dart';

class MessageDto {
  int id;

  String text;

  ClientDto sender;
  ClientDto receiver;

  bool sent;
  bool received;
  bool seen;

  bool displayCheckMark;

  String senderContactName;
  String receiverContactName;

  bool senderOnline;
  bool receiverOnline;

  int senderLastOnlineTimestamp;
  int receiverLastOnlineTimestamp;

  int sentTimestamp;

  int contactBindingId;

  bool chained;

  String messageType;

  String fileName;

  String fileUrl;

  String filePath;

  int fileSizeBytes;

  bool isUploading;

  double uploadProgress;

  Function stopUploadFunc;

  bool deleted;

  bool isDownloadingFile;

  int downloadProgress;

  String downloadTaskId;

  int totalUnreadMessages;

  String recordingDuration;

  bool isRecordingPlaying;

  int nodeId;

  bool pinned = false;

  int pinnedTimestamp;

  bool edited = false;

  ReplyDto replyMessage;

  GlobalKey widgetKey;

  fileSizeFormatted() {
    return filesize(fileSizeBytes);
  }

  MessageDto({this.id, this.text, this.sender, this.receiver, this.sent, this.received, this.seen,
    this.displayCheckMark, this.senderContactName, this.receiverContactName, this.sentTimestamp,
    this.contactBindingId, this.chained,
    this.fileName, this.fileUrl, this.filePath, this.fileSizeBytes,
    this.uploadProgress, this.stopUploadFunc, this.isUploading,
    this.messageType,
    this.deleted = false,
    this.isDownloadingFile = false,
    this.downloadProgress = 0,
    this.totalUnreadMessages = 0,
    this.recordingDuration,
    this.nodeId,
    this.isRecordingPlaying = false,
    this.pinned,
    this.pinnedTimestamp,
    this.edited,
    this.replyMessage
  });

  factory MessageDto.fromJson(Map<String, dynamic> parsedJson) {
    return MessageDto()
      ..id = parsedJson['id'] as int
      ..text = parsedJson['text'] as String
      ..sender = parsedJson['sender'] == null
          ? null
          : ClientDto.fromJson(parsedJson['sender'] as Map<String, dynamic>)
      ..receiver = parsedJson['receiver'] == null
          ? null
          : ClientDto.fromJson(parsedJson['receiver'] as Map<String, dynamic>)
      ..sent = parsedJson['sent'] as bool
      ..received = parsedJson['received'] as bool
      ..seen = parsedJson['seen'] as bool
      ..displayCheckMark = parsedJson['displayCheckMark'] == null
          ? false
          : parsedJson['displayCheckMark'] as bool
      ..senderContactName = parsedJson['senderContactName'] as String
      ..receiverContactName = parsedJson['receiverContactName'] as String
      ..senderOnline = parsedJson['senderOnline'] as bool
      ..receiverOnline = parsedJson['receiverOnline'] as bool
      ..senderLastOnlineTimestamp = parsedJson['senderLastOnlineTimestamp'] as int
      ..receiverLastOnlineTimestamp = parsedJson['receiverLastOnlineTimestamp'] as int
      ..sentTimestamp = parsedJson['sentTimestamp'] as int
      ..contactBindingId = parsedJson['contactBindingId'] as int
      ..nodeId = parsedJson['nodeId'] as int
      ..chained = parsedJson['chained'] == null
          ? false
          : parsedJson['chained'] as bool
      ..fileName = parsedJson['fileName'] as String
      ..filePath = parsedJson['filePath'] as String
      ..fileUrl = parsedJson['fileUrl'] as String
      ..fileSizeBytes = parsedJson['fileSizeBytes'] == null
          ? 0
          : parsedJson['fileSizeBytes'] as int
      ..uploadProgress = 0.0
      ..stopUploadFunc = null
      ..isUploading = false
      ..deleted = parsedJson['deleted'] as bool
      ..totalUnreadMessages = parsedJson['totalUnreadMessages'] == null
          ? 0
          : parsedJson['totalUnreadMessages'] as int
      ..recordingDuration = parsedJson['recordingDuration']
      ..messageType = parsedJson['messageType'] as String
      ..pinned = parsedJson['pinned'] as bool
      ..pinnedTimestamp = parsedJson['pinnedTimestamp'] as int
      ..edited = parsedJson['edited'] as bool
      ..replyMessage = parsedJson['replyMessage'] == null
          ? null
          : ReplyDto.fromJson(parsedJson['replyMessage'] as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sender': sender,
    'receiver': receiver,
    'sent': sent,
    'received': received,
    'seen': seen,
    'displayCheckMark': displayCheckMark,
    'senderContactName': senderContactName,
    'receiverContactName': receiverContactName,
    'senderOnline': senderOnline,
    'receiverOnline': receiverOnline,
    'senderLastOnlineTimestamp': senderLastOnlineTimestamp,
    'receiverLastOnlineTimestamp': receiverLastOnlineTimestamp,
    'sentTimestamp': sentTimestamp,
    'contactBindingId': contactBindingId,
    'chained': chained,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'nodeId': nodeId,
    'filePath': filePath,
    'fileSizeBytes': fileSizeBytes,
    'messageType': messageType,
    'recordingDuration': recordingDuration,
    'deleted': deleted,
    'pinned': pinned,
    'pinnedTimestamp': pinnedTimestamp,
    'edited': edited,
    'replyMessage': replyMessage
  };
}
