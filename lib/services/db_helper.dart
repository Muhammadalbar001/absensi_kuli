import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "AbsensiKuli.db";
  static const _databaseVersion = 1;

  // Membuat instance singleton (agar database tidak dibuka berkali-kali)
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Fungsi untuk membuat file database di HP
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Membuat tabel-tabel saat aplikasi pertama kali diinstal
  Future _onCreate(Database db, int version) async {
    // 1. Tabel Pekerja
    await db.execute('''
      CREATE TABLE pekerja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_hp TEXT,
        posisi TEXT,
        upah_harian INTEGER
      )
    ''');

    // 2. Tabel Absensi
    await db.execute('''
      CREATE TABLE absensi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pekerja_id INTEGER,
        tanggal TEXT NOT NULL,
        status_hadir TEXT,
        jam_lembur INTEGER DEFAULT 0,
        FOREIGN KEY (pekerja_id) REFERENCES pekerja (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Kasbon
    await db.execute('''
      CREATE TABLE kasbon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pekerja_id INTEGER,
        tanggal TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (pekerja_id) REFERENCES pekerja (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- FUNGSI UNTUK PEKERJA ---
  
  Future<int> insertPekerja(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('pekerja', row);
  }

  Future<List<Map<String, dynamic>>> queryAllPekerja() async {
    Database db = await instance.database;
    return await db.query('pekerja', orderBy: "nama ASC");
  }

  Future<int> updatePekerja(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update('pekerja', row, where: 'id = ?', whereArgs: [id]);
  }

  // --- FUNGSI UNTUK ABSENSI ---

  Future<int> simpanAbsensi(Map<String, dynamic> row) async {
    Database db = await instance.database;
    // Gunakan conflictAlgorithm untuk mengupdate jika tanggal & id kuli sama
    return await db.insert('absensi', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryRekap(int pekerjaId, String start, String end) async {
    Database db = await instance.database;
    return await db.query('absensi', 
      where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?', 
      whereArgs: [pekerjaId, start, end]);
  }

  // --- FUNGSI UNTUK KASBON ---

  Future<int> insertKasbon(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('kasbon', row);
  }

  Future<List<Map<String, dynamic>>> queryKasbon(int pekerjaId, String start, String end) async {
    Database db = await instance.database;
    return await db.query('kasbon', 
      where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?', 
      whereArgs: [pekerjaId, start, end]);
  }
}