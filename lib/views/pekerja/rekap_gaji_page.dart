import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';

class RekapGajiPage extends StatefulWidget {
  final Pekerja pekerja;
  RekapGajiPage({required this.pekerja});

  @override
  _RekapGajiPageState createState() => _RekapGajiPageState();
}

class _RekapGajiPageState extends State<RekapGajiPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _dataPrint; // Menyimpan data sementara untuk diprint

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  Future<Map<String, dynamic>> _hitungRekapGaji() async {
    final db = await DatabaseHelper.instance.database;
    String startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    String endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    // 1. Ambil data absensi
    final absensiList = await db.query('absensi',
        where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?',
        whereArgs: [widget.pekerja.id, startStr, endStr]);

    int hadirFull = 0, setengahHari = 0, sakit = 0, izin = 0, alpa = 0;
    int totalLemburNominal = 0;

    for (var a in absensiList) {
      if (a['status_hadir'] == 'Hadir') hadirFull++;
      if (a['status_hadir'] == 'Setengah Hari') setengahHari++;
      if (a['status_hadir'] == 'Sakit') sakit++;
      if (a['status_hadir'] == 'Izin') izin++;
      if (a['status_hadir'] == 'Alpa') alpa++;
      totalLemburNominal += (a['lembur_nominal'] as int? ?? 0);
    }

    // 2. Ambil data kasbon
    final kasbonList = await db.query('kasbon',
        where: 'pekerja_id = ? AND tanggal BETWEEN ? AND ?',
        whereArgs: [widget.pekerja.id, startStr, endStr]);

    double totalKasbon = 0;
    for (var k in kasbonList) {
      totalKasbon += double.parse(k['nominal'].toString());
    }

    // 3. Kalkulasi Gaji
    double gajiPokok = (hadirFull * widget.pekerja.upahHarian) + (setengahHari * 0.5 * widget.pekerja.upahHarian);
    double gajiKotor = gajiPokok + totalLemburNominal;
    double gajiBersih = gajiKotor - totalKasbon;

    return {
      'hadir_full': hadirFull,
      'setengah_hari': setengahHari,
      'sakit': sakit,
      'izin': izin,
      'alpa': alpa,
      'total_lembur': totalLemburNominal,
      'total_kasbon': totalKasbon,
      'detail_kasbon': kasbonList,
      'gaji_pokok': gajiPokok,
      'gaji_kotor': gajiKotor,
      'gaji_bersih': gajiBersih,
    };
  }

  // FUNGSI MEMBUAT DAN MENCETAK PDF
  Future<void> _cetakPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    // Format Tampilan Slip Gaji PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, // Ukuran kertas A5 (Setengah A4) cocok untuk struk
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('SLIP GAJI PEKERJA', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              
              // Info Pekerja
              pw.Text('Nama Pekerja : ${widget.pekerja.nama}'),
              pw.Text('Posisi       : ${widget.pekerja.posisi}'),
              pw.Text('Periode      : ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Rincian Kehadiran
              pw.Text('Rincian Kehadiran:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hadir Penuh: ${data['hadir_full']} hari'),
                  pw.Text('Sakit: ${data['sakit']} hari'),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Setengah Hari: ${data['setengah_hari']} hari'),
                  pw.Text('Izin: ${data['izin']} hari'),
                ]
              ),
              pw.Text('Alpa: ${data['alpa']} hari'),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Rincian Keuangan
              pw.Text('Rincian Gaji:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              _buildPdfRow('Gaji Pokok', currencyFormatter.format(data['gaji_pokok'])),
              _buildPdfRow('Total Lembur', '+ ${currencyFormatter.format(data['total_lembur'])}'),
              _buildPdfRow('Potongan Kasbon', '- ${currencyFormatter.format(data['total_kasbon'])}'),
              
              // Rincian Kasbon
              if (data['detail_kasbon'] != null && (data['detail_kasbon'] as List).isNotEmpty)
                ...((data['detail_kasbon'] as List).map((k) {
                  DateTime tgl = DateTime.parse(k['tanggal']);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('• ${DateFormat('dd/MM').format(tgl)} (${k['keterangan']})', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(currencyFormatter.format(double.parse(k['nominal'].toString())), style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                      ]
                    )
                  );
                }).toList()),

              pw.Divider(thickness: 2),
              
              // Total Bersih
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.all(5),
                child: _buildPdfRow('TOTAL GAJI BERSIH', currencyFormatter.format(data['gaji_bersih']), isBold: true),
              ),
              
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Disetujui Oleh,'),
                    pw.SizedBox(height: 40),
                    pw.Text('( Mandor Proyek )'),
                  ]
                )
              )
            ],
          );
        },
      ),
    );

    // Memunculkan preview PDF yang bisa di-share atau di-print
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Slip_Gaji_${widget.pekerja.nama}');
  }

  // Widget Bantuan untuk PDF
  pw.Widget _buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rekap Gaji: ${widget.pekerja.nama}'), backgroundColor: Colors.blue[800]),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Periode: ${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now());
                    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
                  },
                  child: const Text("Ubah"),
                )
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _hitungRekapGaji(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text("Gagal memuat data"));
                
                var data = snapshot.data!;
                _dataPrint = data; // Simpan data ke variabel global agar bisa diprint

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text("Rincian Kehadiran", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildRekapItem("Hadir Full", "${data['hadir_full']} hari"),
                    _buildRekapItem("Setengah Hari", "${data['setengah_hari']} hari"),
                    _buildRekapItem("Sakit", "${data['sakit']} hari", color: Colors.orange[700]),
                    _buildRekapItem("Izin", "${data['izin']} hari", color: Colors.orange[700]),
                    _buildRekapItem("Alpa", "${data['alpa']} hari", color: Colors.red[700]),
                    
                    const Divider(height: 30),
                    const Text("Rincian Keuangan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildRekapItem("Gaji Pokok", currencyFormatter.format(data['gaji_pokok'])),
                    _buildRekapItem("Total Lembur", "+ ${currencyFormatter.format(data['total_lembur'])}", color: Colors.blue[700]),
                    _buildRekapItem("Total Kasbon", "- ${currencyFormatter.format(data['total_kasbon'])}", color: Colors.red),
                    
                    if (data['detail_kasbon'] != null && (data['detail_kasbon'] as List).isNotEmpty)
                      ...(data['detail_kasbon'] as List).map<Widget>((kasbon) {
                        DateTime tgl = DateTime.parse(kasbon['tanggal']);
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("   • ${DateFormat('dd MMM').format(tgl)} (${kasbon['keterangan']})", style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic)),
                              Text(currencyFormatter.format(double.parse(kasbon['nominal'].toString())), style: TextStyle(color: Colors.red[300], fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),

                    const Divider(thickness: 2, height: 30),
                    _buildRekapItem("TOTAL GAJI BERSIH", currencyFormatter.format(data['gaji_bersih']), isBold: true, color: Colors.green[700]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      // TOMBOL UNTUK MENCETAK PDF
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_dataPrint != null) {
            _cetakPDF(_dataPrint!); // Panggil fungsi cetak dengan data yang ada di layar
          }
        },
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Cetak PDF", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRekapItem(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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