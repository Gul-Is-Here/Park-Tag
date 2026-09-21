/// FR-05: a single message inside a vehicle's chat thread with one scanner.
enum ChatSender { owner, scanner }

enum ChatMessageKind { text, voice, photo }

class ChatMessageModel {
  const ChatMessageModel({
    required this.sender,
    required this.kind,
    required this.timeLabel,
    this.text = '',
    this.voiceDuration = '',
  });

  final ChatSender sender;
  final ChatMessageKind kind;
  final String timeLabel;
  final String text;
  final String voiceDuration;
}
