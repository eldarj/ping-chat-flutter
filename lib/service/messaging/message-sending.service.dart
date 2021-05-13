import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/model/reply-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';

class MessageSendingService {
  final ClientDto peer;

  final String peerContactName;

  final String myContactName;

  final int contactBindingId;

  ClientDto sender;

  initialize() async {
    this.sender = await UserService.getUser();
  }

  MessageSendingService(this.peer, this.peerContactName, this.myContactName, this.contactBindingId) {
    initialize();
  }

  MessageDto sendTextMessage(String text) {
    MessageDto message = _create();
    message.messageType = 'TEXT_MESSAGE';
    message.text = text;

    wsClientService.sendingMessagesPub.sendEvent(message, '/messages/send');

    return message;
  }

  MessageDto sendReply(String text, MessageDto replyMessage) {
    MessageDto message = _create();
    message.messageType = 'TEXT_MESSAGE';
    message.text = text;
    message.replyMessage = ReplyDto.fromMessage(replyMessage);

    wsClientService.sendingMessagesPub.sendEvent(message, '/messages/send');

    return message;
  }

  MessageDto sendEdit(MessageDto message, text) {
    message.text = text;
    wsClientService.sendingMessagesPub.sendEvent(message, '/messages/edit');

    return message;
  }

  MessageDto sendSticker(String stickerCode, {chained: false}) {
    MessageDto message = _create(chained: chained);
    message.messageType = 'STICKER';
    message.text = stickerCode;

    wsClientService.sendingMessagesPub.sendEvent(message, '/messages/send');

    return message;
  }

  MessageDto sendGif(String gifUrl, { chained: false }) {
    MessageDto message = _create(chained: chained);
    message.messageType = 'GIF';
    message.text = gifUrl;

    wsClientService.sendingMessagesPub.sendEvent(message, '/messages/send');

    return message;
  }

  MessageDto addPreparedFile(String fileName, String filePath, String fileUrl,
      int fileSize, String messageType, {chained: false, recordingDuration, text}) {
    MessageDto message = _create(chained: chained);
    message.messageType = messageType;
    message.fileName = fileName;
    message.filePath = filePath;
    message.fileUrl = fileUrl;
    message.fileSizeBytes = fileSize;
    message.uploadProgress = 0.0;
    message.isUploading = true;
    message.recordingDuration = recordingDuration;
    message.text = text;

    wsClientService.sendingMessagesPub.subject.add(message);

    return message;
  }

  void sendFile(MessageDto message) {
    WsClientService.wsClient.send('/messages/send', message);
  }

  MessageDto _create({bool chained = false}) {
    MessageDto message = new MessageDto();
    message.receiver = peer;
    message.sender = sender;
    message.senderContactName = myContactName;
    message.receiverContactName = peerContactName;

    message.sent = false;
    message.received = false;
    message.seen = false;
    message.displayCheckMark = true;
    message.chained = chained;

    message.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    message.contactBindingId = contactBindingId;

    return message;
  }
}
