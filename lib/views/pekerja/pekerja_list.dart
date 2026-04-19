import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';
import 'pekerja_form.dart';
import 'rekap_gaji_page.dart';

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
              TextField(controller: nominalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp ')),
              const SizedBox(height: 12),
              TextField(controller: keteranganController, decoration: const InputDecoration(labelText: 'Keterangan')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                int nominal = int.tryParse(nominalController.text) ?? 0;
                if (nominal > 0) {
                  await DatabaseHelper.instance.insertKasbon({
                    'pekerja_id': pekerja.id, 'tanggal': DateTime.now().toString().split(' ')[0],
                    'nominal': nominal, 'keterangan': keteranganController.text
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kasbon berhasil dicatat'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      },
    );
  }

  void _hapusKuli(Pekerja pekerja) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus ${pekerja.nama}?'),
        content: const Text('Apakah Anda yakin? Semua data absen dan kasbon miliknya akan ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await DatabaseHelper.instance.deletePekerja(pekerja.id);
              Navigator.pop(context);
              _refreshPekerja();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kuli berhasil dihapus'), backgroundColor: Colors.red));
            },
            child: const Text('HAPUS PERMANEN'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitung Hari - Daftar Kuli'), // JUDUL DIPERBARUI
      ),
      body: FutureBuilder<List<Pekerja>>(
        future: _futurePekerja,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 80, color: Colors.grey[300]), const SizedBox(height: 16), Text('Belum ada data kuli', style: TextStyle(color: Colors.grey[400], fontSize: 18))]));
          }

          List<Pekerja> daftarPekerja = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: daftarPekerja.length,
            itemBuilder: (context, index) {
              var pekerja = daftarPekerja[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(radius: 25, backgroundColor: Colors.amber[100], child: Text(pekerja.nama[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 20))),
                        title: Text(pekerja.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('${pekerja.posisi}\nRp ${pekerja.upahHarian}/hari'),
                        isThreeLine: true,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionIcon(Icons.edit, Colors.orange, 'Edit', () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PekerjaForm(pekerja: pekerja)));
                              if (result == true) _refreshPekerja();
                            }),
                            _buildActionIcon(Icons.monetization_on, Colors.green, 'Kasbon', () => _tampilkanDialogKasbon(context, pekerja)),
                            _buildActionIcon(Icons.summarize, Colors.blue, 'Rekap', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RekapGajiPage(pekerja: pekerja)));
                            }),
                            _buildActionIcon(Icons.delete, Colors.red, 'Hapus', () => _hapusKuli(pekerja)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ).animate(delay: (index * 100).ms).fade(duration: 500.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PekerjaForm()));
          if (result == true) _refreshPekerja();
        },
        label: const Text('Kuli Baru'), icon: const Icon(Icons.add),
        backgroundColor: Colors.amber[700], foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}