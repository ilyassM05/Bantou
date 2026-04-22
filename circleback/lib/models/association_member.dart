class AssociationMember {
  final int id;
  final String name;
  final int avatarIndex;

  AssociationMember({
    required this.id,
    required this.name,
    required this.avatarIndex,
  });

  factory AssociationMember.fromJson(Map<String, dynamic> json) {
    return AssociationMember(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      avatarIndex: json['avatar_index'] ?? 0,
    );
  }
}
