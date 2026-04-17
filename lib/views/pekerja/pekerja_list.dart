import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';
import 'pekerja_form.dart';
import '../absensi/absensi_page.dart';
import 'rekap_gaji_page.dart';
import 'rekap_global_page.dart';
import 'makan_page.dart'; // IMPORT HALAMAN MAKAN

class PekerjaList extends StatefulWidget {
  @override
  _PekerjaListState createState() => _PekerjaListState();
}

class _PekerjaListState extends State<PekerjaList> {
  late Future<List<Pekerja>> _futurePekerja;

  @override
  void initState() {
    super.initState();
    _refreshPekerja();
  }

  void _refreshPekerja() {
    setState(() {
      _futurePekerja = DatabaseHelper.instance.queryAllPekerja().then((maps) {
        return maps.map((m) => Pekerja.fromMap(m)).toList();
      });
    });
  }

  void _tampilkanDialogKasbon(BuildContext context, Pekerja pekerja) {
    TextEditingController nominalController = TextEditingController();
    TextEditingController keteranganController = TextEditingController(text: 'Makan/Rokok');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Kasbon: ${pekerja.nama}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nominalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keteranganController,
                decoration: const InputDecoration(labelText: 'Keterangan'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                int nominal = int.tryParse(nominalController.text) ?? 0;
                if (nominal > 0) {
                  await DatabaseHelper.instance.insertKasbon({
                    'pekerja_id': pekerja.id,
                    'tanggal': DateTime.now().toString().split(' ')[0],
                    'nominal': nominal,
                    'keterangan': keteranganController.text
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kasbon berhasil dicatat'), backgroundColor: Colors.green)
                  );
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitung Hari'),
        actions: [
          // TOMBOL MENU BARU: MAKAN
          IconButton(
            icon: const Icon(Icons.fastfood),
            tooltip: 'Biaya Makan',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MakanPage())),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Rekap Master',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RekapGlobalPage())),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Absen Harian',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AbsensiPage())),
          ),
        ],
      ),
      body: FutureBuilder<List<Pekerja>>(
        future: _futurePekerja,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Belum ada data kuli', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                ],
              ),
            );
          }

          List<Pekerja> daftarPekerja = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: daftarPekerja.length,
            itemBuilder: (context, index) {
              var pekerja = daftarPekerja[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.amber[100],
                        child: Text(
                          pekerja.nama[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 22),
                        ),
                      ),
                      title: Text(pekerja.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('${pekerja.posisi}\nRp ${pekerja.upahHarian}/hari'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionIcon(Icons.edit, Colors.orange, () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PekerjaForm(pekerja: pekerja)));
                            if (result == true) _refreshPekerja();
                          }),
                          const SizedBox(width: 8),
                          _buildActionIcon(Icons.monetization_on, Colors.green, () => _tampilkanDialogKasbon(context, pekerja)),
                          const SizedBox(width: 8),
                          _buildActionIcon(Icons.summarize, Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RekapGajiPage(pekerja: pekerja)));
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate(delay: (index * 100).ms) 
              .fade(duration: 500.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PekerjaForm()));
          if (result == true) _refreshPekerja();
        },
        label: const Text('Kuli Baru'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: IconButton(
        constraints: const BoxConstraints(),
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }
}