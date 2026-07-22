import 'package:equatable/equatable.dart';

enum UserRole {
  student,
  teacher,
  parent,
  moderator,
  admin;

  String get label => switch (this) {
        UserRole.student => 'Öğrenci',
        UserRole.teacher => 'Öğretmen',
        UserRole.parent => 'Veli',
        UserRole.moderator => 'Moderatör',
        UserRole.admin => 'Yönetici',
      };

  bool get isSupportStaff =>
      this == UserRole.moderator || this == UserRole.admin;
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.streakDays = 0,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int streakDays;

  int get xpToNextLevel => level * 100;
  double get progressToNextLevel => (xp % 100) / 100.0;

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    int? level,
    int? xp,
    int? streakDays,
    UserRole? role,
  }) => UserProfile(
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    level: level ?? this.level,
    xp: xp ?? this.xp,
    streakDays: streakDays ?? this.streakDays,
    role: role ?? this.role,
  );

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    role,
    avatarUrl,
    level,
    xp,
    streakDays,
  ];
}
