// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message-content.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class MessageText extends StatelessWidget {
  const MessageText(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext _context) => messageText(text);
}

class MessageSticker extends StatelessWidget {
  const MessageSticker(this.text, {Key key}) : super(key: key);

  final dynamic text;

  @override
  Widget build(BuildContext _context) => messageSticker(text);
}

class MessageImage extends StatelessWidget {
  const MessageImage(
      this.size,
      this.filePath,
      this.isPeerMessage,
      this.isDownloadingFile,
      this.isUploading,
      this.uploadProgress,
      {Key key})
      : super(key: key);

  final dynamic size;

  final dynamic filePath;

  final dynamic isPeerMessage;

  final dynamic isDownloadingFile;

  final dynamic isUploading;

  final dynamic uploadProgress;

  @override
  Widget build(BuildContext _context) => messageImage(
      size,
      filePath,
      isPeerMessage,
      isDownloadingFile,
      isUploading,
      uploadProgress);
}

class MessageDeleted extends StatelessWidget {
  const MessageDeleted({Key key}) : super(key: key);

  @override
  Widget build(BuildContext _context) => messageDeleted();
}
