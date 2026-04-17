class Pekerja {
  final int id;
  final String nama;
  final String noHp;
  final String posisi;
  final int upahHarian;

  Pekerja({required this.id, required this.nama, required this.noHp, required this.posisi, required this.upahHarian});

  // Mengubah data dari Database (Map) ke Objek Flutter
  factory Pekerja.fromMap(Map<String, dynamic> json) => Pekerja(
    id: json['id'],
    nama: json['nama'],
    noHp: json['no_hp'] ?? '',
    posisi: json['posisi'] ?? 'Kuli',
    upahHarian: json['upah_harian'],
  );

  // Mengubah Objek Flutter ke Map untuk disimpan ke Database
  Map<String, dynamic> toMap() => {
    'id': id == 0 ? null : id, // biarkan null jika tambah baru agar auto-increment
    'nama': nama,
    'no_hp': noHp,
    'posisi': posisi,
    'upah_harian': upahHarian,
  };
}