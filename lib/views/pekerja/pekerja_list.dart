import 'package:flutter/material.dart';
import '../../models/pekerja.dart';
import '../../services/api_service.dart';
import 'pekerja_form.dart';
import '../absensi/absensi_page.dart';
import 'rekap_gaji_page.dart'; 

class PekerjaList extends StatefulWidget {
  @override
  _PekerjaListState createState() => _PekerjaListState();
}

class _PekerjaListState extends State<PekerjaList> {
  final ApiService _apiService = ApiService();
  late Future<List<Pekerja>> _futurePekerja;

  @override
  void initState() {
    super.initState();
    _refreshPekerja();
  }

  void _refreshPekerja() {
    setState(() {
      _futurePekerja = _apiService.getPekerja();
    });
  }

  // Fungsi memunculkan Pop-up Input Kasbon
  void _tampilkanDialogKasbon(BuildContext context, Pekerja pekerja) {
    TextEditingController nominalController = TextEditingController();
    TextEditingController keteranganController = TextEditingController(text: 'Makan/Rokok');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Kasbon: ${pekerja.nama}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nominalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: keteranganController,
                    decoration: InputDecoration(labelText: 'Keterangan'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  onPressed: isSaving ? null : () async {
                    setStateDialog(() => isSaving = true);
                    
                    String tglHariIni = DateTime.now().toString().split(' ')[0];
                    int nominal = int.tryParse(nominalController.text) ?? 0;

                    if (nominal > 0) {
                      bool sukses = await _apiService.simpanKasbon(pekerja.id, tglHariIni, nominal, keteranganController.text);
                      if (sukses) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kasbon Rp $nominal berhasil dicatat!'), backgroundColor: Colors.green));
                      } else {
                        setStateDialog(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencatat kasbon'), backgroundColor: Colors.red));
                      }
                    } else {
                       setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Simpan'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Kuli Proyek'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: Icon(Icons.assignment_turned_in),
            tooltip: 'Catat Absensi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AbsensiPage()),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<Pekerja>>(
        future: _futurePekerja,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada data pekerja.'));
          }

          List<Pekerja> daftarPekerja = snapshot.data!;
          return ListView.builder(
            itemCount: daftarPekerja.length,
            itemBuilder: (context, index) {
              var pekerja = daftarPekerja[index];
              return Card(
                clipBehavior: Clip.antiAlias, // Agar ujungnya tetap membulat saat disentuh
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    // Opsional: Aksi jika kartu disentuh
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.amber[100], // Warna latar inisial
                        child: Text(
                          pekerja.nama[0].toUpperCase(), // Ambil huruf pertama
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 20),
                        ),
                      ),
                      title: Text(pekerja.nama, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${pekerja.posisi}\nRp ${pekerja.upahHarian}/hari',
                          style: TextStyle(height: 1.3), // Jarak antar baris teks
                        ),
                      ),
                      isThreeLine: true, // Beri ruang agar teks tidak terpotong
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Edit
                          Container(
                            decoration: BoxDecoration(color: Colors.orange[50], shape: BoxShape.circle),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange[700], size: 20),
                              tooltip: 'Edit Data',
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PekerjaForm(pekerja: pekerja)),
                                );
                                if (result == true) _refreshPekerja();
                              },
                            ),
                          ),
                          SizedBox(width: 8),

                          // Tombol Kasbon
                          Container(
                            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                            child: IconButton(
                              icon: Icon(Icons.monetization_on, color: Colors.green[700], size: 20),
                              tooltip: 'Beri Kasbon',
                              onPressed: () => _tampilkanDialogKasbon(context, pekerja),
                            ),
                          ),
                          SizedBox(width: 8),

                          // Navigasi ke Rekap Gaji
                          Container(
                            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                            child: IconButton(
                              icon: Icon(Icons.summarize, color: Colors.blue[700], size: 20),
                              tooltip: 'Rekap Gaji',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RekapGajiPage(pekerja: pekerja),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PekerjaForm()),
          );
          if (result == true) _refreshPekerja();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}