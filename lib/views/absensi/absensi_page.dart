import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';

class AbsensiPage extends StatefulWidget {
  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  late Future<List<Pekerja>> _futurePekerja;
  DateTime _tanggalDipilih = DateTime.now();
  bool _isSaving = false;

  Map<int, String> _statusHadirMap = {};
  
  // KODE BARU: Menggunakan Controller agar mandor bisa mengetik nominal
  Map<int, TextEditingController> _lemburControllers = {}; 

  @override
  void initState() {
    super.initState();
    _futurePekerja = DatabaseHelper.instance.queryAllPekerja().then((maps) {
      return maps.map((m) => Pekerja.fromMap(m)).toList();
    });
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), 
    );
    if (picked != null && picked != _tanggalDipilih) {
      setState(() => _tanggalDipilih = picked);
    }
  }

  void _simpanSemuaAbsensi(List<Pekerja> daftarPekerja) async {
    setState(() => _isSaving = true);
    String tglFormat = DateFormat('yyyy-MM-dd').format(_tanggalDipilih);

    try {
      for (var pekerja in daftarPekerja) {
        String status = _statusHadirMap[pekerja.id] ?? 'Hadir';
        
        // Mengambil angka dari ketikan mandor (jika kosong, anggap 0)
        int lemburNominal = int.tryParse(_lemburControllers[pekerja.id]?.text ?? '0') ?? 0;

        await DatabaseHelper.instance.simpanAbsensi({
          'pekerja_id': pekerja.id,
          'tanggal': tglFormat,
          'status_hadir': status,
          'lembur_nominal': lemburNominal // Simpan langsung nominal rupiahnya
        });
      }
      
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absensi berhasil disimpan!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ada data yang gagal disimpan'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catat Absensi')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_tanggalDipilih)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _pilihTanggal(context),
                  icon: Icon(Icons.calendar_month),
                  label: Text('Ubah'),
                )
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Pekerja>>(
              future: _futurePekerja,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('Belum ada data kuli.'));

                List<Pekerja> pekerjaList = snapshot.data!;
                return ListView.builder(
                  itemCount: pekerjaList.length,
                  itemBuilder: (context, index) {
                    var pekerja = pekerjaList[index];
                    _statusHadirMap.putIfAbsent(pekerja.id, () => 'Hadir');
                    _lemburControllers.putIfAbsent(pekerja.id, () => TextEditingController(text: '0'));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pekerja.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _statusHadirMap[pekerja.id],
                                    decoration: InputDecoration(labelText: 'Status', isDense: true),
                                    items: ['Hadir', 'Setengah Hari', 'Sakit', 'Izin', 'Alpa'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                    onChanged: (val) => setState(() => _statusHadirMap[pekerja.id] = val!),
                                  ),
                                ),
                                SizedBox(width: 10),
                                
                                // KODE BARU: Text Input untuk uang lembur
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _lemburControllers[pekerja.id],
                                    decoration: InputDecoration(labelText: 'Lembur (Rp)', isDense: true, prefixText: 'Rp '),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isSaving ? null : () {
             // Tutup keyboard jika masih terbuka
             FocusScope.of(context).unfocus();
             _futurePekerja.then((list) => _simpanSemuaAbsensi(list));
          },
          child: _isSaving ? CircularProgressIndicator(color: Colors.white) : Text('SIMPAN ABSENSI HARI INI'),
        ),
      ),
    );
  }
}