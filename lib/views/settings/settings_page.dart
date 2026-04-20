import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/db_helper.dart';

class SettingsPage extends StatelessWidget {
  
  // Fungsi Backup: Share file SQLite ke WhatsApp/Drive
  void _backupData(BuildContext context) async {
    try {
      String dbPath = await DatabaseHelper.instance.getDatabasePath();
      File dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        await Share.shareXFiles([XFile(dbPath)], text: 'Backup Database Hitung Hari Proyek');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database tidak ditemukan!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // Fungsi Restore: Mengambil file dari HP untuk menimpa data
  void _restoreData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null) {
        String filePath = result.files.single.path!;
        
        // Pastikan ekstensi file valid (biasanya .db atau tanpa ekstensi dari whatsapp)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Database?'),
            content: const Text('PERINGATAN: Semua data proyek yang ada di HP ini sekarang akan ditimpa dengan data dari file backup. Lanjutkan?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  await DatabaseHelper.instance.restoreDatabase(filePath);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore Berhasil! Restart aplikasi untuk efek penuh.'), backgroundColor: Colors.green));
                },
                child: const Text('TIMPA DATA'),
              )
            ],
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Restore: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Keamanan'), backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Keamanan Data Proyek (Offline)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.cloud_upload, color: Colors.white)),
              title: const Text('Backup Database'),
              subtitle: const Text('Kirim salinan data ke WhatsApp/Drive'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _backupData(context),
            ),
          ).animate().slideX(begin: 0.1),
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.settings_backup_restore, color: Colors.white)),
              title: const Text('Restore Database'),
              subtitle: const Text('Pulihkan data dari file backup (.db)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _restoreData(context),
            ),
          ).animate().slideX(begin: 0.1, delay: 100.ms),
          
          const SizedBox(height: 30),
          
          // Desain Empty State gaya modern
          Center(
            child: Column(
              children: [
                Icon(Icons.shield_moon_outlined, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text("Aplikasi 100% Offline", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).disabledColor)),
                Text("Data Anda aman di dalam memori HP.", style: TextStyle(fontSize: 12, color: Theme.of(context).disabledColor)),
              ],
            ).animate().fade(delay: 400.ms),
          )
        ],
      ),
    );
  }
}