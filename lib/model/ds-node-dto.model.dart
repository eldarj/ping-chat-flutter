import 'package:filesize/filesize.dart';

class DSNodeDto {
  int id;

  int ownerId;

  int receiverId;

  int parentDirectoryNodeId;

  String nodeName;

  String nodePath;

  String description;

  String fileUrl;

  String pathOnSourceDevice;

  int fileSizeBytes;

  int createdTimestamp;

  int lastModifiedTimestamp;

  String nodeType;

  String recordingDuration;

  bool selected;

  bool isDownloading;

  String downloadTaskId;

  fileSizeFormatted() {
    return filesize(fileSizeBytes);
  }

  DSNodeDto({this.id, this.ownerId, this.receiverId, this.parentDirectoryNodeId,
    this.nodeName, this.nodePath, this.nodeType, this.fileUrl,
    this.pathOnSourceDevice, this.fileSizeBytes, this.recordingDuration,
    this.createdTimestamp, this.lastModifiedTimestamp, this.description,
    this.selected = false
  });

  factory DSNodeDto.fromJson(Map<String, dynamic> parsedJson) {
    return parsedJson == null ? parsedJson : DSNodeDto(
      id: parsedJson['id'] as int,
      ownerId: parsedJson['ownerId'] as int,
      receiverId: parsedJson['receiverId'] as int,
      parentDirectoryNodeId: parsedJson['parentDirectoryNodeId'] as int,
      nodeName: parsedJson['nodeName'] as String,
      nodePath: parsedJson['nodePath'] as String,
      description: parsedJson['description'] as String,
      nodeType: parsedJson['nodeType'] as String,
      recordingDuration: parsedJson['recordingDuration'] as String,
      fileUrl: parsedJson['fileUrl'] as String,
      pathOnSourceDevice: parsedJson['pathOnSourceDevice'] as String,
      fileSizeBytes: parsedJson['fileSizeBytes'] != null
          ? parsedJson['fileSizeBytes'] as int : 0,
      createdTimestamp: parsedJson['createdTimestamp'] as int,
      lastModifiedTimestamp: parsedJson['lastModifiedTimestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'receiverId': receiverId,
    'parentDirectoryNodeId': parentDirectoryNodeId,
    'nodeName': nodeName,
    'nodePath': nodePath,
    'description': description,
    'recordingDuration': recordingDuration,
    'nodeType': nodeType,
    'fileUrl': fileUrl,
    'pathOnSourceDevice': pathOnSourceDevice,
    'fileSizeBytes': fileSizeBytes,
    'createdTimestamp': createdTimestamp,
    'lastModifiedTimestamp': lastModifiedTimestamp,
  };
}
