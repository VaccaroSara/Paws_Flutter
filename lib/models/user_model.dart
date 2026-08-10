class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String city;
  final String province;
  final String cap;
  final String phone;
  final String accountType;
  final String profileImageUri;

  UserModel({
    this.uid = '',
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.city = '',
    this.province = '',
    this.cap = '',
    this.phone = '',
    this.accountType = 'Private User',
    this.profileImageUri = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      city: map['city'] as String? ?? '',
      province: map['province'] as String? ?? '',
      cap: map['cap'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      accountType: map['accountType'] as String? ?? 'Private User',
      profileImageUri: map['profileImageUri'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'city': city,
      'province': province,
      'cap': cap,
      'phone': phone,
      'accountType': accountType,
      'profileImageUri': profileImageUri,
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? city,
    String? province,
    String? cap,
    String? phone,
    String? accountType,
    String? profileImageUri,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      city: city ?? this.city,
      province: province ?? this.province,
      cap: cap ?? this.cap,
      phone: phone ?? this.phone,
      accountType: accountType ?? this.accountType,
      profileImageUri: profileImageUri ?? this.profileImageUri,
    );
  }
}
