class Category {
  final int? id;
  final String name;
  final String emoji;
  final int color;

  const Category({
    this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'color': color,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        color: map['color'] as int,
      );

  Category copyWith({int? id, String? name, String? emoji, int? color}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
      );
}
