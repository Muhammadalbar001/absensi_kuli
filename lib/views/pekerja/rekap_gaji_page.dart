import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pekerja.dart';
import '../../services/api_service.dart';

class RekapGajiPage extends StatefulWidget {
  final Pekerja pekerja;
  RekapGajiPage({required this.pekerja});

  @override
  _RekapGajiPageState createState() => _RekapGajiPageState();
}

class _RekapGajiPageState extends State<RekapGajiPage> {
  final ApiService _apiService = ApiService();
  
  DateTime _startDate = DateTime.now().subtract(Duration(days: 6));
  DateTime _endDate = DateTime.now();

  final TextEditingController _tarifLemburController = TextEditingController(text: '20000');

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    String startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    String endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    
    int tarifLembur = int.tryParse(_tarifLemburController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Gaji: ${widget.pekerja.nama}'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          // Bagian Filter & Input Panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                // Baris 1: Filter Tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Periode: ${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                      child: Text("Ubah Periode"),
                    )
                  ],
                ),
                SizedBox(height: 10),
                // Baris 2: Input Tarif Lembur + Tombol Hitung
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tarifLemburController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tarif Lembur per Jam',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.white,
                          filled: true
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: EdgeInsets.symmetric(vertical: 14)
                      ),
                      onPressed: () {
                        setState(() {});
                        FocusScope.of(context).unfocus(); 
                      },
                      child: Text('Hitung', style: TextStyle(color: Colors.white)),
                    )
                  ],
                )
              ],
            ),
          ),
          
          // Bagian Kertas Struk/Rincian Gaji
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _apiService.getRekapGaji(widget.pekerja.id, startStr, endStr, tarifLembur),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Gagal memuat data"));
                
                var data = snapshot.data!['rincian'];

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _buildRekapItem("Hadir Full", "${data['hadir_full']} hari"),
                    _buildRekapItem("Setengah Hari", "${data['setengah_hari']} hari"),
                    _buildRekapItem("Total Lembur", "${data['total_jam_lembur']} jam"),
                    Divider(),
                    _buildRekapItem("Gaji Pokok", currencyFormatter.format(data['gaji_pokok'])),
                    
                    _buildRekapItem("Upah Lembur\n(x ${currencyFormatter.format(tarifLembur)}/jam)", currencyFormatter.format(data['upah_lembur'])),
                    
                    // Total Kasbon
                    _buildRekapItem("Total Kasbon", "- ${currencyFormatter.format(data['total_kasbon'])}", color: Colors.red),
                    
                    // --- Rincian Tanggal Kasbon ---
                    if (data['detail_kasbon'] != null && data['detail_kasbon'].isNotEmpty)
                      ...data['detail_kasbon'].map<Widget>((kasbon) {
                        DateTime tgl = DateTime.parse(kasbon['tanggal']);
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("   • ${DateFormat('dd MMM').format(tgl)} (${kasbon['keterangan']})", 
                                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic)),
                              // PERUBAHAN DI SINI: Menggunakan double.parse agar tidak error melihat nilai desimal MySQL (.00)
                              Text(currencyFormatter.format(double.parse(kasbon['nominal'].toString())), 
                                style: TextStyle(color: Colors.red[300], fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                    // ---------------------------------------

                    Divider(thickness: 2),
                    _buildRekapItem(
                      "TOTAL GAJI BERSIH", 
                      currencyFormatter.format(data['gaji_bersih']),
                      isBold: true,
                      color: Colors.green[700]
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapItem(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 15)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 16, color: color)),
        ],
      ),
    );
  }
}