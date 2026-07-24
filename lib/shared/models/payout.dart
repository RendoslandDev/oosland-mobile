class MonthlyPayout {
  const MonthlyPayout({
    required this.userId,
    required this.month,
    this.likeCount = 0,
    this.poolCents = 0,
    this.payoutCents = 0,
    this.computedAt,
  });

  final String userId;
  final DateTime month;
  final int likeCount;
  final int poolCents;
  final int payoutCents;
  final DateTime? computedAt;

  double get payoutDollars => payoutCents / 100;
  double get poolDollars => poolCents / 100;

  factory MonthlyPayout.fromJson(Map<String, dynamic> json) {
    return MonthlyPayout(
      userId: json['user_id'] as String,
      month: DateTime.parse(json['month'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      poolCents: json['pool_cents'] as int? ?? 0,
      payoutCents: json['payout_cents'] as int? ?? 0,
      computedAt: json['computed_at'] != null
          ? DateTime.parse(json['computed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'month': month.toIso8601String(),
        'like_count': likeCount,
        'pool_cents': poolCents,
        'payout_cents': payoutCents,
      };
}
