class UserProfile {
  final String age;
  final String height;
  final String weight;
  final String activityLevel; // sedentary / moderate / active
  final String goal; // weight_loss / diabetes
  final String gender;

  UserProfile({
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
    required this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      "age": age,
      "height": height,
      "weight": weight,
      "activity_level": activityLevel,
      "goal": goal.replaceAll("-", "_"), // normalize
      "gender": gender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      age: map["age"] ?? "",
      height: map["height"] ?? "",
      weight: map["weight"] ?? "",
      activityLevel: map["activity_level"] ?? "sedentary",
      goal: map["goal"]?.replaceAll("-", "_") ?? "weight_loss",
      gender: map["gender"] ?? "male",
    );
  }
}
