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

/// Kullanıcı gönderimi bir video mu yoksa bir resim mi? Storage
/// maliyetini kontrol altında tutmak için kullanıcılar ikisinden
/// sadece birini yükleyebiliyor (bkz. ReelSubmitPage).
enum ReelMediaType { video, image }

/// Reel için tek bir yorum.
class ReelComment extends Equatable {
  const ReelComment({
    required this.user,
    required this.text,
    this.isMe = false,
  });
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
    this.videoUrl,
    this.mediaType = ReelMediaType.video,
    this.uploaderId,
    this.expiresAt,
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
  /// Oyunun gerçek adresi — kullanıcı gönderimlerinde https link (CTA
  /// butonu bunu tarayıcıda açar), demo seed verisinde uygulama-içi rota
  /// (`/lessons` gibi, geriye dönük uyumluluk için `context.push` ile açılır).
  final String gameUrl;
  /// Oynanış medyası — kullanıcı yüklemelerinde dolu (demo modda yerel
  /// dosya yolu, gerçek modda Firebase Storage indirme linki). [mediaType]
  /// bunun video mu resim mi olduğunu belirtir. `null` ise
  /// [ReelBackgroundPainter] arka plan olarak kullanılır (demo reels).
  final String? videoUrl;
  final ReelMediaType mediaType;
  final String? uploaderId;
  /// Storage maliyetini kontrol altında tutmak için kullanıcı
  /// gönderimleri geçicidir — bu tarihten sonra herhangi bir istemci
  /// gönderiyi (ve Storage'daki dosyasını) temizleyebilir (bkz.
  /// firestore.rules `reels` koleksiyonu delete kuralı). Seed/demo
  /// reels'te `null`, hiç süresi dolmaz.
  final DateTime? expiresAt;

  GameReel copyWith({
    int? likes,
    bool? liked,
    bool? saved,
    bool? following,
    List<ReelComment>? comments,
  }) => GameReel(
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
    videoUrl: videoUrl,
    mediaType: mediaType,
    uploaderId: uploaderId,
    expiresAt: expiresAt,
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
    videoUrl,
    mediaType,
    uploaderId,
    expiresAt,
  ];
}
