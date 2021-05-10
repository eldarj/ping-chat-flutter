import 'package:filesize/filesize.dart';
import 'package:flutterping/model/message-dto.model.dart';


class ReplyDto {
  int id;

  String text;

  String messageType;

  int sentTimestamp;

  String fileName;

  String fileUrl;

  String filePath;

  int fileSizeBytes;

  String recordingDuration;

  bool isRecordingPlaying;

  int nodeId;

  int messageId;

  fileSizeFormatted() {
    return filesize(fileSizeBytes);
  }

  ReplyDto({
    this.id,
    this.text,
    this.fileName, this.fileUrl, this.filePath, this.fileSizeBytes,
    this.messageType,
    this.recordingDuration,
    this.nodeId,
    this.isRecordingPlaying = false,
    this.messageId,
    this.sentTimestamp,
  });

  factory ReplyDto.fromJson(Map<String, dynamic> parsedJson) {
    return ReplyDto()
      ..id = parsedJson['id'] as int
      ..text = parsedJson['text'] as String
      ..nodeId = parsedJson['nodeId'] as int
      ..fileName = parsedJson['fileName'] as String
      ..filePath = parsedJson['filePath'] as String
      ..sentTimestamp = parsedJson['sentTimestamp'] as int
      ..fileUrl = parsedJson['fileUrl'] as String
      ..fileSizeBytes = parsedJson['fileSizeBytes'] == null
          ? 0
          : parsedJson['fileSizeBytes'] as int
      ..recordingDuration = parsedJson['recordingDuration']
      ..messageType = parsedJson['messageType'] as String
      ..messageId = parsedJson['messageId'] as int;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'nodeId': nodeId,
    'filePath': filePath,
    'fileSizeBytes': fileSizeBytes,
    'messageType': messageType,
    'sentTimestamp': sentTimestamp,
    'recordingDuration': recordingDuration,
    'messageId': messageId
  };

  factory ReplyDto.fromMessage(MessageDto message) {
    return ReplyDto()
      ..text = message.text
      ..nodeId = message.nodeId
      ..fileName = message.fileName
      ..filePath = message.filePath
      ..fileUrl = message.fileUrl
      ..fileSizeBytes = message.fileSizeBytes
      ..recordingDuration = message.recordingDuration
      ..messageType = message.messageType
      ..messageId = message.id
      ..sentTimestamp = message.sentTimestamp;
  }
}
