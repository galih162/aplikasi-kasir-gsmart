class UserModel {
  final String id;
  final String email;
  final String nama;
  final String jabatan; // admin / kasir

  UserModel({
    required this.id,
    required this.email,
    required this.nama,
    required this.jabatan,
  });

  factory UserModel.fromDatabase(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      nama: map['nama'],
      jabatan: map['jabatan'],
    );
  }

  get role => null;

  bool? get isAdmin => null;
}
