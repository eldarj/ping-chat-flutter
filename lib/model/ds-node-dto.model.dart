class DSNodeDto {
  int id;

  int ownerId;

  int receiverId;

  int parentDirectoryNodeId;

  String nodeName;

  String nodePath;

  bool empty;

  String fileUrl;

  String pathOnSourceDevice;

  int fileSizeBytes;

  int createdTimestamp;

  int lastModifiedTimestamp;

  DSNodeDto({this.id, this.ownerId, this.receiverId, this.parentDirectoryNodeId,
    this.nodeName, this.nodePath, this.empty, this.fileUrl,
    this.pathOnSourceDevice, this.fileSizeBytes,
    this.createdTimestamp, this.lastModifiedTimestamp});

  factory DSNodeDto.fromJson(Map<String, dynamic> parsedJson) {
    return parsedJson == null ? parsedJson : DSNodeDto(
      id: parsedJson['id'] as int,
      ownerId: parsedJson['ownerId'] as int,
      receiverId: parsedJson['receiverId'] as int,
      parentDirectoryNodeId: parsedJson['parentDirectoryNodeId'] as int,
      nodeName: parsedJson['nodeName'] as String,
      nodePath: parsedJson['nodePath'] as String,
      empty: parsedJson['empty'] != null
          ? parsedJson['empty'] as bool : false,
      fileUrl: parsedJson['fileUrl'] as String,
      pathOnSourceDevice: parsedJson['pathOnSourceDevice'] as String,
      fileSizeBytes: parsedJson['fileSizeBytes'] != null
          ? parsedJson['empty'] as int : 0,
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
    'empty': empty,
    'fileUrl': fileUrl,
    'pathOnSourceDevice': pathOnSourceDevice,
    'fileSizeBytes': fileSizeBytes,
    'createdTimestamp': createdTimestamp,
    'lastModifiedTimestamp': lastModifiedTimestamp,
  };
}
