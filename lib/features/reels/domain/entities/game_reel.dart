import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Reels için accent renk ailesi (HTML tasarımdaki gibi).
enum ReelAccent { gold, mint, coral, violet }

extension ReelAccentColors on ReelAccent {
  Color get color {
    switch (this) {
      case ReelAccent.gold:
        return const Color(0xFFFFC145);
      case ReelAccent.mint:
        return const Color(0xFF6EE7B7);
      case ReelAccent.coral:
        return const Color(0xFFFF6B6B);
      case ReelAccent.violet:
        return const Color(0xFFA78BFA);
    }
  }
}

/// Reel için tek bir yorum.
class ReelComment extends Equatable {
  const ReelComment({required this.user, required this.text, this.isMe = false});
  final String user;
  final String text;
  final bool isMe;

  @override
  List<Object?> get props => [user, text, isMe];
}

/// Tek bir oyun vitrini (reel).
class GameReel extends Equatable {
  const GameReel({
    required this.id,
    required this.devName,
    required this.devTag,
    required this.title,
    required this.caption,
    required this.tags,
    required this.accent,
    required this.symbols,
    required this.hud,
    required this.likes,
    required this.comments,
    required this.gameUrl,
    this.liked = false,
    this.saved = false,
    this.following = false,
  });

  final String id;
  final String devName;
  final String devTag;
  final String title;
  final String caption;
  final String tags;
  final ReelAccent accent;
  final List<String> symbols;
  final String hud;
  final int likes;
  final bool liked;
  final bool saved;
  final bool following;
  final List<ReelComment> comments;
  final String gameUrl;

  GameReel copyWith({
    int? likes,
    bool? liked,
    bool? saved,
    bool? following,
    List<ReelComment>? comments,
  }) =>
      GameReel(
        id: id,
        devName: devName,
        devTag: devTag,
        title: title,
        caption: caption,
        tags: tags,
        accent: accent,
        symbols: symbols,
        hud: hud,
        likes: likes ?? this.likes,
        liked: liked ?? this.liked,
        saved: saved ?? this.saved,
        following: following ?? this.following,
        comments: comments ?? this.comments,
        gameUrl: gameUrl,
      );

  String get avatarText =>
      devName.replaceAll('@', '').substring(0, 2).toUpperCase();

  @override
  List<Object?> get props => [
        id,
        devName,
        devTag,
        title,
        caption,
        tags,
        accent,
        symbols,
        hud,
        likes,
        liked,
        saved,
        following,
        comments,
        gameUrl,
      ];
}