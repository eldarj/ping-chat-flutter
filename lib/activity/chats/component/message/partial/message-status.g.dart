// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message-status.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class MessageStatusRow extends StatelessWidget {
  const MessageStatusRow(
      this.isPeerMessage,
      this.sentTimestamp,
      this.displayPlaceholderCheckMark,
      this.displayTimestamp,
      this.sent,
      this.received,
      this.seen,
      this.pinned,
      {Key key})
      : super(key: key);

  final dynamic isPeerMessage;

  final dynamic sentTimestamp;

  final dynamic displayPlaceholderCheckMark;

  final dynamic displayTimestamp;

  final dynamic sent;

  final dynamic received;

  final dynamic seen;

  final bool pinned;

  @override
  Widget build(BuildContext _context) => messageStatusRow(
      isPeerMessage,
      sentTimestamp,
      displayPlaceholderCheckMark,
      displayTimestamp,
      sent,
      received,
      seen,
      pinned);
}

class MessageStatus extends StatelessWidget {
  const MessageStatus(this.sentTimestamp, this.sent, this.received, this.seen, this.pinned,
      {Key key,
      this.displayStatusIcon = true,
      this.displayPlaceholderCheckMark = false})
      : super(key: key);

  final dynamic sentTimestamp;

  final dynamic sent;

  final dynamic received;

  final dynamic seen;

  final dynamic displayStatusIcon;

  final dynamic displayPlaceholderCheckMark;

  final bool pinned;

  @override
  Widget build(BuildContext _context) =>
      messageStatus(sentTimestamp, sent, received, seen, pinned,
          displayStatusIcon: displayStatusIcon,
          displayPlaceholderCheckMark: displayPlaceholderCheckMark);
}

class MessagePeerStatus extends StatelessWidget {
  const MessagePeerStatus(this.sentTimestamp, this.pinned, {Key key}) : super(key: key);

  final dynamic sentTimestamp;

  final bool pinned;

  @override
  Widget build(BuildContext _context) => messagePeerStatus(sentTimestamp, pinned);
}
