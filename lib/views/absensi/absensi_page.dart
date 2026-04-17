import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../models/pekerja.dart';
import '../../services/api_service.dart';

class AbsensiPage extends StatefulWidget {
  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Pekerja>> _futurePekerja;
  
  DateTime _tanggalDipilih = DateTime.now();
  bool _isSaving = false;

  // Menyimpan status kehadiran
  Map<int, String> _statusHadirMap = {};
  
  // PERUBAHAN: Kita ganti Controller Text menjadi Map angka biasa
  // untuk menyimpan nilai dari Dropdown Lembur
  Map<int, int> _lemburMap = {}; 

  @override
  void initState() {
    super.initState();
    _futurePekerja = _apiService.getPekerja();
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), 
    );
    if (picked != null && picked != _tanggalDipilih) {
      setState(() {
        _tanggalDipilih = picked;
      });
    }
  }

  void _simpanSemuaAbsensi(List<Pekerja> daftarPekerja) async {
    setState(() => _isSaving = true);
    
    String tglFormat = DateFormat('yyyy-MM-dd').format(_tanggalDipilih);
    bool adaError = false;

    for (var pekerja in daftarPekerja) {
      String status = _statusHadirMap[pekerja.id] ?? 'Hadir';
      
      // PERUBAHAN: Mengambil nilai langsung dari Map Dropdown (default 0)
      int lembur = _lemburMap[pekerja.id] ?? 0;

      bool sukses = await _apiService.simpanAbsensi(pekerja.id, tglFormat, status, lembur);
      if (!sukses) adaError = true;
    }

    setState(() => _isSaving = false);

    if (adaError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ada data yang gagal disimpan'), backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absensi tanggal $tglFormat berhasil disimpan!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catat Absensi'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal: ${DateFormat('dd MMMM yyyy').format(_tanggalDipilih)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                    // PERUBAHAN: Set default nilai lembur ke 0 (Tidak Lembur)
                    _lemburMap.putIfAbsent(pekerja.id, () => 0);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pekerja.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                // Dropdown Status Hadir
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _statusHadirMap[pekerja.id],
                                    decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                                    items: ['Hadir', 'Setengah Hari', 'Sakit', 'Izin', 'Alpa'].map((String val) {
                                      return DropdownMenuItem(value: val, child: Text(val));
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _statusHadirMap[pekerja.id] = val!;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 10),
                                
                                // PERUBAHAN: Mengubah Text Input menjadi Dropdown Lembur
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<int>(
                                    value: _lemburMap[pekerja.id],
                                    decoration: InputDecoration(labelText: 'Lembur', border: OutlineInputBorder(), isDense: true),
                                    items: [
                                      DropdownMenuItem(value: 0, child: Text('Tidak Lembur')),
                                      DropdownMenuItem(value: 1, child: Text('1 Jam')),
                                      DropdownMenuItem(value: 2, child: Text('2 Jam')),
                                      DropdownMenuItem(value: 3, child: Text('3 Jam')),
                                      DropdownMenuItem(value: 4, child: Text('4 Jam (Malam)')),
                                      DropdownMenuItem(value: 5, child: Text('5 Jam (S/d 23.00)')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _lemburMap[pekerja.id] = val!;
                                      });
                                    },
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isSaving ? null : () {
             _futurePekerja.then((list) => _simpanSemuaAbsensi(list));
          },
          child: _isSaving 
            ? CircularProgressIndicator(color: Colors.white)
            : Text('SIMPAN ABSENSI HARI INI', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}