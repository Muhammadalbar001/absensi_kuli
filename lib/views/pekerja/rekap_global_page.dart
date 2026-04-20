import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart'; // IMPORT ANIMASI
import '../../models/pekerja.dart';
import '../../services/db_helper.dart';

class RekapGlobalPage extends StatefulWidget {
  @override
  _RekapGlobalPageState createState() => _RekapGlobalPageState();
}

class _RekapGlobalPageState extends State<RekapGlobalPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _dataPrint; 

  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  Future<Map<String, dynamic>> _hitungRekapGlobal() async {
    final db = await DatabaseHelper.instance.database;
    String startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    String endStr = DateFormat('yyyy-MM-dd').format(_endDate);

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

    var makanMaps = await db.query('makan', where: 'tanggal BETWEEN ? AND ?', whereArgs: [startStr, endStr]);
    double totalBiayaMakan = 0;
    for (var m in makanMaps) { totalBiayaMakan += double.parse(m['total_harga'].toString()); }

    return {
      'list_rekap': listRekap,
      'grand_total_gaji': grandTotalGaji,
      'total_makan': totalBiayaMakan,
      'total_proyek': grandTotalGaji + totalBiayaMakan,
    };
  }

  Future<void> _exportExcelCSV(Map<String, dynamic> data) async {
    List<List<dynamic>> rows = [];

    rows.add(['LAPORAN KEUANGAN PROYEK']);
    rows.add(['Periode:', '${DateFormat('dd MMM yyyy').format(_startDate)} s/d ${DateFormat('dd MMM yyyy').format(_endDate)}']);
    rows.add([]); 
    rows.add(['Nama Kuli', 'Hadir Full', 'Setengah Hari', 'Lembur (Rp)', 'Kasbon (Rp)', 'Gaji Bersih (Rp)']);

    List<Map<String, dynamic>> listPekerja = data['list_rekap'];
    for (var item in listPekerja) {
      rows.add([
        item['nama'], item['hadir'], item['setengah'],
        item['lembur'], item['kasbon'], item['gaji_bersih'],
      ]);
    }

    rows.add([]); 
    rows.add(['', '', '', '', 'Subtotal Gaji Kuli', data['grand_total_gaji']]);
    rows.add(['', '', '', '', 'Total Biaya Makan', data['total_makan']]);
    rows.add(['', '', '', '', 'GRAND TOTAL', data['total_proyek']]);

    // TIDAK MENGGUNAKAN CONST PADA LISTTOCSV
    String csv = ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Laporan_Proyek_${DateFormat('dd_MMM_yyyy').format(DateTime.now())}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Berikut adalah Laporan Keuangan Proyek format Excel.');
  }

  Future<void> _cetakPDFLaporan(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    List<Map<String, dynamic>> listPekerja = data['list_rekap'];

    final headers = ['Nama Kuli', 'Hadir', '1/2 Hr', 'Lembur', 'Kasbon', 'Gaji Bersih'];
    final tableData = listPekerja.map((item) {
      return [
        item['nama'], item['hadir'].toString(), item['setengah'].toString(),
        currencyFormatter.format(item['lembur']), currencyFormatter.format(item['kasbon']), currencyFormatter.format(item['gaji_bersih']),
      ];
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('LAPORAN KEUANGAN PROYEK', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} s/d ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers, data: tableData, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700), cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              ),
              pw.SizedBox(height: 20), pw.Divider(thickness: 2), pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal Gaji Kuli:', style: const pw.TextStyle(fontSize: 14)), pw.Text(currencyFormatter.format(data['grand_total_gaji']), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))]),
              pw.SizedBox(height: 5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Biaya Makan:', style: const pw.TextStyle(fontSize: 14)), pw.Text('+ ' + currencyFormatter.format(data['total_makan']), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))]),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10), color: PdfColors.grey200,
                child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('GRAND TOTAL (KAS DIPERLUKAN):', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)), pw.Text(currencyFormatter.format(data['total_proyek']), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))])
              ),
              pw.Spacer(),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [pw.Text('Disetujui Oleh,'), pw.SizedBox(height: 50), pw.Text('( Mandor Proyek )')]))
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Laporan_Proyek_${DateFormat('dd_MMM_yyyy').format(DateTime.now())}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan Proyek'),
        backgroundColor: Colors.teal[700], foregroundColor: Colors.white
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), color: Colors.teal[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Periode: ${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2022), lastDate: DateTime.now());
                    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
                  },
                  icon: const Icon(Icons.date_range, size: 18), label: const Text("Ubah"),
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
                var data = snapshot.data!; _dataPrint = data; 
                List<Map<String, dynamic>> listPekerja = data['list_rekap'];

                return Column(
                  children: [
                    Expanded(
                      child: listPekerja.isEmpty 
                      ? const Center(child: Text('Tidak ada aktivitas kuli di periode ini'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.teal[50]),
                              columnSpacing: 25,
                              columns: const [
                                DataColumn(label: Text('Nama Kuli', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('1/2 Hr', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Lembur', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Kasbon', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Gaji Bersih', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: listPekerja.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(item['hadir'].toString())),
                                  DataCell(Text(item['setengah'].toString())),
                                  DataCell(Text(currencyFormatter.format(item['lembur']), style: TextStyle(color: Colors.blue[700]))),
                                  DataCell(Text(currencyFormatter.format(item['kasbon']), style: TextStyle(color: Colors.red[700]))),
                                  DataCell(Text(currencyFormatter.format(item['gaji_bersih']), style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ).animate().fade().scaleXY(begin: 0.95, alignment: Alignment.topCenter), // ANIMASI TABEL EXCEL
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))]),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Gaji Kuli:", style: TextStyle(color: Colors.grey)), Text(currencyFormatter.format(data['grand_total_gaji']), style: const TextStyle(fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 5),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Makan:", style: TextStyle(color: Colors.grey)), Text("+ ${currencyFormatter.format(data['total_makan'])}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
                            const Divider(thickness: 2, height: 20),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("TOTAL KESELURUHAN:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[900], fontSize: 16)), Text(currencyFormatter.format(data['total_proyek']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal[800]))]),
                            
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: () { if (_dataPrint != null) _cetakPDFLaporan(_dataPrint!); },
                                    icon: const Icon(Icons.picture_as_pdf), 
                                    label: const Text("PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: () { if (_dataPrint != null) _exportExcelCSV(_dataPrint!); },
                                    icon: const Icon(Icons.table_view), 
                                    label: const Text("EXCEL", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOutCubic) // ANIMASI KOTAK TOTAL DARI BAWAH
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