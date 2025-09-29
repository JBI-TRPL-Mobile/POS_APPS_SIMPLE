class User {
  final int? id;
  final String fullname;
  final String username;
  final String email;
  final String password;

  User(
      {this.id,
      required this.fullname,
      required this.username,
      required this.email,
      required this.password});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': fullname,
      'username': username,
      'email': email,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullname: map['fullname'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
    );
  }
}
