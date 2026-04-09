class UserProfile {
  final int id;
  final String name;
  final String role;
  final int avatarIndex;
  final String? profilePictureUrl;
  final String? company;
  final String? jobTitle;
  final String? communityRole;
  final String? city;
  final String? bio;
  final String? website;
  final String? email;
  final String? phone;
  final String privacyLevel; // 'public' | 'association' | 'private'

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarIndex,
    this.profilePictureUrl,
    this.company,
    this.jobTitle,
    this.communityRole,
    this.city,
    this.bio,
    this.website,
    this.email,
    this.phone,
    required this.privacyLevel,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'member',
      avatarIndex: json['avatarIndex'] ?? 0,
      profilePictureUrl: json['profilePicture'] as String?,
      company: json['company'],
      jobTitle: json['jobTitle'],
      communityRole: json['communityRole'],
      city: json['city'],
      bio: json['bio'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      privacyLevel: json['privacyLevel'] ?? 'association',
    );
  }

  bool get hasContactInfo => email != null || phone != null;
}
