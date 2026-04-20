import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/db_helper.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  Future<Map<String, dynamic>> _getDashboardStats() async {
    final db = await DatabaseHelper.instance.database;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Total Pekerja
    var pekerja = await db.query('pekerja');
    
    // 2. Kuli Hadir Hari Ini
    var absen = await db.query('absensi', where: 'tanggal = ? AND status_hadir = ?', whereArgs: [today, 'Hadir']);
    
    // 3. Total Kasbon Hari Ini
    var kasbon = await db.query('kasbon', where: 'tanggal = ?', whereArgs: [today]);
    double totalKasbon = 0;
    for (var k in kasbon) { totalKasbon += double.parse(k['nominal'].toString()); }

    // 4. Total Makan Hari Ini
    var makan = await db.query('makan', where: 'tanggal = ?', whereArgs: [today]);
    double totalMakan = 0;
    for (var m in makan) { totalMakan += double.parse(m['total_harga'].toString()); }

    return {
      'total_kuli': pekerja.length,
      'kuli_hadir': absen.length,
      'kasbon_hari_ini': totalKasbon,
      'makan_hari_ini': totalMakan,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Proyek'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Gagal memuat data"));
          
          var data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async { setState(() {}); },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Ringkasan Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Grid Kartu Ringkasan
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(context, "Kuli Terdaftar", data['total_kuli'].toString(), Icons.people, Colors.blue),
                    _buildStatCard(context, "Hadir Hari Ini", data['kuli_hadir'].toString(), Icons.check_circle, Colors.green),
                    _buildStatCard(context, "Kasbon Hari Ini", currencyFormatter.format(data['kasbon_hari_ini']), Icons.monetization_on, Colors.orange),
                    _buildStatCard(context, "Biaya Makan", currencyFormatter.format(data['makan_hari_ini']), Icons.fastfood, Colors.red),
                  ].animate(interval: 100.ms).fade().scaleXY(begin: 0.8),
                ),
                
                const SizedBox(height: 40),
                
                // Ilustrasi Kosong / Hiasan Bawah
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.dashboard_customize_outlined, size: 100, color: Theme.of(context).disabledColor.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text("Selamat Bekerja!", style: TextStyle(fontSize: 18, color: Theme.of(context).disabledColor, fontWeight: FontWeight.bold)),
                      Text("Pilih menu di bawah untuk mengelola proyek", style: TextStyle(color: Theme.of(context).disabledColor)),
                    ],
                  ).animate().fade(delay: 500.ms).slideY(begin: 0.2),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: value.length > 8 ? 16 : 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}