class Email {
  final String id;
  final String subject;
  final String content;
  final String sender;
  final String businessName;
  final DateTime timestamp;
  final bool isRead;
  final List<EmailAttachment> attachments;
  final String shortContent;

  Email({
    required this.id,
    required this.subject,
    required this.content,
    required this.sender,
    required this.businessName,
    required this.timestamp,
    this.isRead = false,
    this.attachments = const [],
  }) : shortContent = _generateShortContent(content);

  static String _generateShortContent(String content) {
    if (content.length <= 100) {
      return content;
    }
    return '${content.substring(0, 100)}...';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'content': content,
      'sender': sender,
      'businessName': businessName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'],
      subject: json['subject'],
      content: json['content'],
      sender: json['sender'],
      businessName: json['businessName'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      attachments: (json['attachments'] as List?)
          ?.map((a) => EmailAttachment.fromJson(a))
          .toList() ?? [],
    );
  }

  Email copyWith({
    String? id,
    String? subject,
    String? content,
    String? sender,
    String? businessName,
    DateTime? timestamp,
    bool? isRead,
    List<EmailAttachment>? attachments,
  }) {
    return Email(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      businessName: businessName ?? this.businessName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachments: attachments ?? this.attachments,
    );
  }
}

class EmailAttachment {
  final String id;
  final String name;
  final String type;
  final int size;
  final String? base64Data;

  EmailAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    this.base64Data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'size': size,
      'base64Data': base64Data,
    };
  }

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      size: json['size'],
      base64Data: json['base64Data'],
    );
  }

  String get fileSize {
    if (size < 1024) {
      return '${size} B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
} 