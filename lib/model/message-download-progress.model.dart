import 'package:flutter_downloader/flutter_downloader.dart';

class MessageDownloadProgress {

  String taskId;
  DownloadTaskStatus status;
  int progress;

  MessageDownloadProgress(this.taskId, this.status, this.progress);
}
