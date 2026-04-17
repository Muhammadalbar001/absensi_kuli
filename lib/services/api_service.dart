import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Tambahkan ini untuk mengecek Web/Platform
import '../models/pekerja.dart';

class ApiService {
  // Atur URL otomatis berdasarkan platform (Web vs Android)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // Untuk Chrome/Web
    } else {
      return 'http://10.0.2.2:8000/api';  // Untuk Emulator Android
    }
  }

  // 1. Fungsi GET: Mengambil data pekerja
  Future<List<Pekerja>> getPekerja() async {
    final response = await http.get(Uri.parse('$baseUrl/pekerja'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List data = jsonResponse['data']; 
      return data.map((pekerja) => Pekerja.fromJson(pekerja)).toList();
    } else {
      throw Exception('Gagal mengambil data pekerja');
    }
  }

  // 2. Fungsi POST: Menambah pekerja
  Future<bool> tambahPekerja(String nama, String noHp, String posisi, int upahHarian) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pekerja'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama': nama,
        'no_hp': noHp,
        'posisi': posisi,
        'upah_harian': upahHarian,
      }),
    );

    return response.statusCode == 201;
  }

  // 3. Fungsi POST: Menyimpan data absensi
  Future<bool> simpanAbsensi(int pekerjaId, String tanggal, String statusHadir, int jamLembur) async {
    final response = await http.post(
      Uri.parse('$baseUrl/absensi'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pekerja_id': pekerjaId,
        'tanggal': tanggal,
        'status_hadir': statusHadir,
        'jam_lembur': jamLembur,
      }),
    );

    return response.statusCode == 200;
  }

  // 4. Fungsi POST: Menyimpan data kasbon
  Future<bool> simpanKasbon(int pekerjaId, String tanggal, int nominal, String keterangan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/kasbon'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pekerja_id': pekerjaId,
        'tanggal': tanggal,
        'nominal': nominal,
        'keterangan': keterangan,
      }),
    );

    return response.statusCode == 201;
  }

  // 5. Fungsi GET: Mengambil rekap gaji (UPDATE: Tambah parameter upahLembur)
  Future<Map<String, dynamic>> getRekapGaji(int id, String startDate, String endDate, int upahLembur) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rekap/$id?start_date=$startDate&end_date=$endDate&upah_lembur=$upahLembur'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Gagal memuat rekap gaji');
    }
  }

  // Fungsi PUT: Mengubah data pekerja yang sudah ada
  Future<bool> editPekerja(int id, String nama, String noHp, String posisi, int upahHarian) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pekerja/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama': nama,
        'no_hp': noHp,
        'posisi': posisi,
        'upah_harian': upahHarian,
      }),
    );

    return response.statusCode == 200;
  }
}