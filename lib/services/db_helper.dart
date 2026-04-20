import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "AbsensiKuli.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pekerja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        no_hp TEXT,
        posisi TEXT,
        upah_harian INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE absensi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pekerja_id INTEGER,
        tanggal TEXT NOT NULL,
        status_hadir TEXT,
        lembur_nominal INTEGER DEFAULT 0,
        FOREIGN KEY (pekerja_id) REFERENCES pekerja (id) ON DELETE CASCADE
      )
    ''');
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
    await db.execute('''
      CREATE TABLE makan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        jumlah_bungkus INTEGER NOT NULL,
        harga_satuan INTEGER NOT NULL,
        total_harga INTEGER NOT NULL,
        keterangan TEXT
      )
    ''');
  }

  // --- CRUD PEKERJA ---
  Future<int> insertPekerja(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('pekerja', row); }
  Future<List<Map<String, dynamic>>> queryAllPekerja() async { Database db = await instance.database; return await db.query('pekerja', orderBy: "nama ASC"); }
  Future<int> updatePekerja(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['id']; return await db.update('pekerja', row, where: 'id = ?', whereArgs: [id]); }
  Future<int> deletePekerja(int id) async { Database db = await instance.database; return await db.delete('pekerja', where: 'id = ?', whereArgs: [id]); }

  // --- CRUD ABSENSI ---
  Future<int> simpanAbsensi(Map<String, dynamic> row) async {
    Database db = await instance.database;
    var existing = await db.query('absensi', where: 'pekerja_id = ? AND tanggal = ?', whereArgs: [row['pekerja_id'], row['tanggal']]);
    if (existing.isNotEmpty) { return await db.update('absensi', row, where: 'id = ?', whereArgs: [existing.first['id']]); } 
    else { return await db.insert('absensi', row); }
  }
  Future<List<Map<String, dynamic>>> queryAbsensiByDate(String tanggal) async { Database db = await instance.database; return await db.query('absensi', where: 'tanggal = ?', whereArgs: [tanggal]); }

  // --- CRUD KASBON ---
  Future<int> insertKasbon(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('kasbon', row); }
  // KODE BARU: UPDATE DAN DELETE KASBON
  Future<int> updateKasbon(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['id']; return await db.update('kasbon', row, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteKasbon(int id) async { Database db = await instance.database; return await db.delete('kasbon', where: 'id = ?', whereArgs: [id]); }

  // --- CRUD MAKAN ---
  Future<int> insertMakan(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('makan', row); }
  Future<List<Map<String, dynamic>>> queryMakanByDate(String start, String end) async { Database db = await instance.database; return await db.query('makan', where: 'tanggal BETWEEN ? AND ?', whereArgs: [start, end], orderBy: 'tanggal DESC'); }
  Future<int> updateMakan(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['id']; return await db.update('makan', row, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteMakan(int id) async { Database db = await instance.database; return await db.delete('makan', where: 'id = ?', whereArgs: [id]); }
}