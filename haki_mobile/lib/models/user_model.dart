class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? publicKey;
  final String? statusMessage;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.publicKey,
    this.statusMessage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      publicKey: json['publicKey'],
      statusMessage: json['statusMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'publicKey': publicKey,
      'statusMessage': statusMessage,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? publicKey,
    String? statusMessage,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      publicKey: publicKey ?? this.publicKey,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
