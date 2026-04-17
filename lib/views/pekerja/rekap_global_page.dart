import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';

class RekapGlobalPage extends StatefulWidget {
  @override
  _RekapGlobalPageState createState() => _RekapGlobalPageState();
}

class _RekapGlobalPageState extends State<RekapGlobalPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  Future<Map<String, dynamic>> _hitungRekapGlobal() async {
    final db = await DatabaseHelper.instance.database;
    String startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    String endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    // 1. Hitung Gaji Kuli
    var pekerjaMaps = await DatabaseHelper.instance.queryAllPekerja();
    List<Pekerja> pekerjaList = pekerjaMaps.map((m) => Pekerja.fromMap(m)).toList();

    List<Map<String, dynamic>> listRekap = [];
    double grandTotalGaji = 0;

    for (var p in pekerjaList) {
      var absensiList = await db.query('absensi', where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?', whereArgs: [p.id, startStr, endStr]);
      int hadirFull = 0, setengahHari = 0, totalLemburNominal = 0;
      for (var a in absensiList) {
        if (a['status_hadir'] == 'Hadir') hadirFull++;
        if (a['status_hadir'] == 'Setengah Hari') setengahHari++;
        totalLemburNominal += (a['lembur_nominal'] as int? ?? 0);
      }

      var kasbonList = await db.query('kasbon', where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?', whereArgs: [p.id, startStr, endStr]);
      double totalKasbon = 0;
      for (var k in kasbonList) { totalKasbon += double.parse(k['nominal'].toString()); }

      double gajiPokok = (hadirFull * p.upahHarian) + (setengahHari * 0.5 * p.upahHarian);
      double gajiBersih = (gajiPokok + totalLemburNominal) - totalKasbon;

      if (hadirFull > 0 || setengahHari > 0 || totalLemburNominal > 0 || totalKasbon > 0) {
        listRekap.add({
          'nama': p.nama, 'hadir': hadirFull, 'setengah': setengahHari,
          'lembur': totalLemburNominal, 'kasbon': totalKasbon, 'gaji_bersih': gajiBersih,
        });
        grandTotalGaji += gajiBersih;
      }
    }

    // 2. Hitung Biaya Makan
    var makanMaps = await db.query('makan', where: 'tanggal BETWEEN ? AND ?', whereArgs: [startStr, endStr]);
    double totalBiayaMakan = 0;
    for (var m in makanMaps) {
      totalBiayaMakan += double.parse(m['total_harga'].toString());
    }

    return {
      'list_rekap': listRekap,
      'grand_total_gaji': grandTotalGaji,
      'total_makan': totalBiayaMakan,
      'total_proyek': grandTotalGaji + totalBiayaMakan,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Anggaran Proyek'), backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Periode: ${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now());
                    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text("Ubah"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _hitungRekapGlobal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text("Gagal memuat data"));
                
                var data = snapshot.data!;
                List<Map<String, dynamic>> listPekerja = data['list_rekap'];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: listPekerja.length,
                        itemBuilder: (context, index) {
                          var item = listPekerja[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(currencyFormatter.format(item['gaji_bersih']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Hadir: ${item['hadir']} | 1/2 Hari: ${item['setengah']}", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                      Text("Lembur: +${currencyFormatter.format(item['lembur'])}", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                                      Text("Kasbon: -${currencyFormatter.format(item['kasbon'])}", style: TextStyle(color: Colors.red[700], fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Grand Total (Paling Bawah)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))]),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Gaji Kuli:", style: TextStyle(color: Colors.grey)),
                              Text(currencyFormatter.format(data['grand_total_gaji']), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Biaya Makan:", style: TextStyle(color: Colors.grey)),
                              Text("+ ${currencyFormatter.format(data['total_makan'])}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          const Divider(thickness: 2, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("TOTAL KESELURUHAN:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[900], fontSize: 16)),
                              Text(currencyFormatter.format(data['total_proyek']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal[800])),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}