import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Bir Python becerisini temsil eden ada.
/// Örnek: Değişkenler Adası, Döngüler Adası, Fonksiyonlar Adası.
class LearningIsland extends Equatable {
  const LearningIsland({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
    required this.color,
    required this.gradient,
    required this.order,
    required this.nodes,
    this.size = 60.0,
    this.unlocked = true,
    this.x = 0,
    this.y = 0,
    this.z = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String emoji;
  final Color color;
  final List<Color> gradient;
  final int order;
  final List<LearningNode> nodes;
  // 3D harita koordinatları (izometrik camera için)
  final double size;
  final bool unlocked;
  final double x;
  final double y;
  final double z;

  int get totalNodes => nodes.length;
  int get completedNodes => nodes.where((n) => n.isCompleted).length;
  bool get allCompleted => totalNodes > 0 && completedNodes == totalNodes;
  double get progress {
    if (totalNodes == 0) return 0;
    return completedNodes / totalNodes;
  }

  LearningIsland copyWith({
    double? size,
    bool? unlocked,
    double? x,
    double? y,
    double? z,
    List<LearningNode>? nodes,
  }) => LearningIsland(
    id: id,
    title: title,
    subtitle: subtitle,
    description: description,
    emoji: emoji,
    color: color,
    gradient: gradient,
    order: order,
    nodes: nodes ?? this.nodes,
    size: size ?? this.size,
    unlocked: unlocked ?? this.unlocked,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
  );

  @override
  List<Object?> get props => [id, title, nodes, x, y, z, size, unlocked];
}

/// Ada içindeki tek bir öğrenme adımı.
class LearningNode extends Equatable {
  /// Base constructor — yeni node oluştururken kullanılır.
  /// Varsayılan: kilitli değil, tamamlanmamış, skor yok.
  const LearningNode({
    required this.id,
    required this.title,
    required this.description,
    required this.tutorial,
    required this.starterCode,
    required this.solution,
    required this.expectedOutput,
    required this.points,
    required this.emoji,
    required this.order,
    this.hints = const [],
    this.isCompleted = false,
    this.isLocked = false,
    this.bestScore,
  });

  final String id;
  final String title;
  final String description;
  final String tutorial;
  final String starterCode;
  final String solution;
  final String expectedOutput;
  final int points;
  final String emoji;
  final int order;
  /// Progressive hints shown before the full solution — the editor
  /// reveals these one at a time (bkz. `_HintPanel` in node_editor_page),
  /// only offering the actual solution once all hints have been seen.
  final List<String> hints;

  // Runtime state (sadece UI'da set edilir)
  final bool isCompleted;
  final bool isLocked;
  final int? bestScore;

  const LearningNode.completed({
    required this.id,
    required this.title,
    required this.description,
    required this.tutorial,
    required this.starterCode,
    required this.solution,
    required this.expectedOutput,
    required this.points,
    required this.emoji,
    required this.order,
    required this.bestScore,
    this.hints = const [],
  }) : isCompleted = true,
       isLocked = false;

  const LearningNode.locked({
    required this.id,
    required this.title,
    required this.description,
    required this.tutorial,
    required this.starterCode,
    required this.solution,
    required this.expectedOutput,
    required this.points,
    required this.emoji,
    required this.order,
    this.hints = const [],
  }) : isCompleted = false,
       isLocked = true,
       bestScore = null;

  const LearningNode.available({
    required this.id,
    required this.title,
    required this.description,
    required this.tutorial,
    required this.starterCode,
    required this.solution,
    required this.expectedOutput,
    required this.points,
    required this.emoji,
    required this.order,
    this.hints = const [],
  }) : isCompleted = false,
       isLocked = false,
       bestScore = null;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    isCompleted,
    isLocked,
    bestScore,
  ];
}
