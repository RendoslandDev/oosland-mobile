class MonthlyChallenge {
  const MonthlyChallenge({
    required this.id,
    required this.month,
    required this.title,
    this.theme = '',
    this.description = '',
    this.coverUrl,
    this.prizePoolCents = 0,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.entryCount = 0,
    this.enteredByMe = false,
  });

  final String id;
  final DateTime month;
  final String title;
  final String theme;
  final String description;
  final String? coverUrl;
  final int prizePoolCents;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;

  // Hydrated client-side.
  final int entryCount;
  final bool enteredByMe;

  double get prizePoolDollars => prizePoolCents / 100;

  MonthlyChallenge copyWith({int? entryCount, bool? enteredByMe}) {
    return MonthlyChallenge(
      id: id,
      month: month,
      title: title,
      theme: theme,
      description: description,
      coverUrl: coverUrl,
      prizePoolCents: prizePoolCents,
      startsAt: startsAt,
      endsAt: endsAt,
      createdAt: createdAt,
      entryCount: entryCount ?? this.entryCount,
      enteredByMe: enteredByMe ?? this.enteredByMe,
    );
  }

  factory MonthlyChallenge.fromJson(Map<String, dynamic> json) {
    return MonthlyChallenge(
      id: json['id'] as String,
      month: DateTime.parse(json['month'] as String),
      title: json['title'] as String,
      theme: json['theme'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      prizePoolCents: json['prize_pool_cents'] as int? ?? 0,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      entryCount: json['entry_count'] as int? ?? 0,
      enteredByMe: json['entered_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month.toIso8601String(),
        'title': title,
        'theme': theme,
        'description': description,
        'cover_url': coverUrl,
        'prize_pool_cents': prizePoolCents,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
      };
}

class ChallengeEntry {
  const ChallengeEntry({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.postId,
    this.createdAt,
  });

  final String id;
  final String challengeId;
  final String userId;
  final String? postId;
  final DateTime? createdAt;

  factory ChallengeEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeEntry(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'challenge_id': challengeId,
        'user_id': userId,
        'post_id': postId,
      };
}
