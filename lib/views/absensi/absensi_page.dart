import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_animate/flutter_animate.dart'; // IMPORT ANIMASI
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
  Map<int, TextEditingController> _lemburControllers = {}; 

  @override
  void initState() {
    super.initState();
    _loadPekerjaDanAbsensi();
  }

  void _loadPekerjaDanAbsensi() {
    setState(() {
      _futurePekerja = DatabaseHelper.instance.queryAllPekerja().then((maps) async {
        List<Pekerja> pekerjaList = maps.map((m) => Pekerja.fromMap(m)).toList();
        String tglFormat = DateFormat('yyyy-MM-dd').format(_tanggalDipilih);
        var absenHariIni = await DatabaseHelper.instance.queryAbsensiByDate(tglFormat);
        
        _statusHadirMap.clear();
        _lemburControllers.clear();

        for (var p in pekerjaList) {
          _statusHadirMap[p.id] = 'Hadir';
          _lemburControllers[p.id] = TextEditingController(text: '0');
          var existingData = absenHariIni.where((a) => a['pekerja_id'] == p.id).toList();
          if (existingData.isNotEmpty) {
            _statusHadirMap[p.id] = existingData.first['status_hadir'];
            _lemburControllers[p.id]!.text = existingData.first['lembur_nominal'].toString();
          }
        }
        return pekerjaList;
      });
    });
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: _tanggalDipilih, firstDate: DateTime(2020), lastDate: DateTime.now(), 
    );
    if (picked != null && picked != _tanggalDipilih) {
      setState(() { _tanggalDipilih = picked; });
      _loadPekerjaDanAbsensi();
    }
  }

  void _simpanSemuaAbsensi(List<Pekerja> daftarPekerja) async {
    setState(() => _isSaving = true);
    String tglFormat = DateFormat('yyyy-MM-dd').format(_tanggalDipilih);

    try {
      for (var pekerja in daftarPekerja) {
        String status = _statusHadirMap[pekerja.id] ?? 'Hadir';
        int lemburNominal = int.tryParse(_lemburControllers[pekerja.id]?.text ?? '0') ?? 0;

        await DatabaseHelper.instance.simpanAbsensi({
          'pekerja_id': pekerja.id, 'tanggal': tglFormat,
          'status_hadir': status, 'lembur_nominal': lemburNominal 
        });
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absensi berhasil disimpan!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan'), backgroundColor: Colors.red));
    }
  }

  Color _getBadgeColor(String status) {
    switch (status) {
      case 'Hadir': return Colors.green;
      case 'Setengah Hari': return Colors.blue;
      case 'Sakit': return Colors.orange;
      case 'Izin': return Colors.teal;
      case 'Alpa': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Harian'), 
        backgroundColor: Colors.indigo[600], foregroundColor: Colors.white
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), color: Colors.indigo[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_tanggalDipilih)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: () => _pilihTanggal(context), icon: const Icon(Icons.calendar_month, size: 18), label: const Text('Ubah'))
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Pekerja>>(
              future: _futurePekerja,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada data kuli.'));

                List<Pekerja> pekerjaList = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: pekerjaList.length,
                  itemBuilder: (context, index) {
                    var pekerja = pekerjaList[index];
                    String currentStatus = _statusHadirMap[pekerja.id] ?? 'Hadir';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _getBadgeColor(currentStatus).withOpacity(0.5), width: 2)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pekerja.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6, runSpacing: -8,
                              children: ['Hadir', 'Setengah Hari', 'Sakit', 'Izin', 'Alpa'].map((status) {
                                bool isSelected = currentStatus == status;
                                return ChoiceChip(
                                  label: Text(status, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: _getBadgeColor(status),
                                  backgroundColor: Colors.grey[200],
                                  showCheckmark: false,
                                  onSelected: (bool selected) {
                                    if (selected) setState(() => _statusHadirMap[pekerja.id] = status);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lemburControllers[pekerja.id],
                              decoration: const InputDecoration(labelText: 'Bonus Lembur Hari Ini (Rp)', isDense: true, prefixText: 'Rp '),
                              keyboardType: TextInputType.number,
                            )
                          ],
                        ),
                      ),
                    ).animate(delay: (index * 50).ms).fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut); // ANIMASI MASUK KARTU ABSEN
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () {
           FocusScope.of(context).unfocus();
           _futurePekerja.then((list) => _simpanSemuaAbsensi(list));
        },
        label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN ABSENSI', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.save),
        backgroundColor: Colors.indigo[600], foregroundColor: Colors.white,
      ).animate().scale(delay: 300.ms),
    );
  }
}