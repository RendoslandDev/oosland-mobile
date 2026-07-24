import 'profile.dart';

class GiftType {
  const GiftType({
    required this.id,
    required this.name,
    required this.icon,
    this.pointValue = 0,
  });

  final String id;
  final String name;
  final String icon;
  final int pointValue;

  factory GiftType.fromJson(Map<String, dynamic> json) {
    return GiftType(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      pointValue: json['point_value'] as int? ?? 0,
    );
  }
}

class Gift {
  const Gift({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.giftType,
    this.postId,
    this.campaignId,
    this.roomId,
    this.message = '',
    this.createdAt,
    this.sender,
    this.recipient,
    this.giftTypeData,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String giftType;
  final String? postId;
  final String? campaignId;
  final String? roomId;
  final String message;
  final DateTime? createdAt;
  final Profile? sender;
  final Profile? recipient;
  final GiftType? giftTypeData;

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      giftType: json['gift_type'] as String,
      postId: json['post_id'] as String?,
      campaignId: json['campaign_id'] as String?,
      roomId: json['room_id'] as String?,
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      sender: json['sender'] != null
          ? Profile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      recipient: json['recipient'] != null
          ? Profile.fromJson(json['recipient'] as Map<String, dynamic>)
          : null,
      giftTypeData: json['gift_types'] != null
          ? GiftType.fromJson(json['gift_types'] as Map<String, dynamic>)
          : null,
    );
  }
}
