class UserProfile {
  final String name;
  final int age;
  final double weight;

  const UserProfile({
    required this.name,
    required this.age,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'weight': weight};

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] as String? ?? '').trim(),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse('${json['age']}') ?? 0,
      weight: json['weight'] is num
          ? (json['weight'] as num).toDouble()
          : double.tryParse('${json['weight']}') ?? 0,
    );
  }

  bool get isComplete => name.isNotEmpty && age > 0 && weight > 0;
}
