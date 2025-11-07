class UserSession {
  final int? id;
  final int userId;
  final String sessionToken;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String deviceInfo;
  final String? ipAddress;
  final bool isActive;
  final DateTime? endedAt;

  UserSession({
    this.id,
    required this.userId,
    required this.sessionToken,
    required this.createdAt,
    this.expiresAt,
    required this.deviceInfo,
    this.ipAddress,
    this.isActive = true,
    this.endedAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid => isActive && !isExpired;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'session_token': sessionToken,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'is_active': isActive ? 1 : 0,
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'],
      userId: map['user_id'],
      sessionToken: map['session_token'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      expiresAt: map['expires_at'] != null 
          ? DateTime.parse(map['expires_at'])
          : null,
      deviceInfo: map['device_info'] ?? '',
      ipAddress: map['ip_address'],
      isActive: map['is_active'] == 1,
      endedAt: map['ended_at'] != null 
          ? DateTime.parse(map['ended_at'])
          : null,
    );
  }

  UserSession copyWith({
    int? id,
    int? userId,
    String? sessionToken,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? deviceInfo,
    String? ipAddress,
    bool? isActive,
    DateTime? endedAt,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionToken: sessionToken ?? this.sessionToken,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      isActive: isActive ?? this.isActive,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  String toString() {
    return 'UserSession(id: $id, userId: $userId, isActive: $isActive, isExpired: $isExpired)';
  }
}