class UserModel {
  final String? id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final bool isAnonymous;

  UserModel({
    this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.isAnonymous = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'isAnonymous': isAnonymous,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
              : null,
      isAnonymous: json['isAnonymous'] ?? true,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    bool? isAnonymous,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, isAnonymous: $isAnonymous)';
  }
}
