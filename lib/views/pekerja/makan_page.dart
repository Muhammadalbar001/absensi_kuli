import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/db_helper.dart';

class MakanPage extends StatefulWidget {
  @override
  _MakanPageState createState() => _MakanPageState();
}

class _MakanPageState extends State<MakanPage> {
  final _jumlahController = TextEditingController();
  final _hargaController = TextEditingController(text: '15000');
  final _ketController = TextEditingController();
  DateTime _tanggalDipilih = DateTime.now();
  int? _editId; 
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  void _simpanMakan() async {
    int jumlah = int.tryParse(_jumlahController.text) ?? 0;
    int harga = int.tryParse(_hargaController.text) ?? 0;
    
    if (jumlah > 0 && harga > 0) {
      Map<String, dynamic> rowData = {
        'tanggal': DateFormat('yyyy-MM-dd').format(_tanggalDipilih),
        'jumlah_bungkus': jumlah, 'harga_satuan': harga,
        'total_harga': jumlah * harga, 'keterangan': _ketController.text,
      };

      if (_editId == null) {
        await DatabaseHelper.instance.insertMakan(rowData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan makan disimpan!'), backgroundColor: Colors.green));
      } else {
        rowData['id'] = _editId;
        await DatabaseHelper.instance.updateMakan(rowData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan berhasil diperbarui!'), backgroundColor: Colors.orange));
      }
      _resetForm();
      setState(() {});
      FocusScope.of(context).unfocus(); 
    }
  }

  void _resetForm() {
    setState(() {
      _editId = null; _jumlahController.clear(); _hargaController.text = '15000';
      _ketController.clear(); _tanggalDipilih = DateTime.now();
    });
  }

  void _editData(Map<String, dynamic> data) {
    setState(() {
      _editId = data['id']; _tanggalDipilih = DateTime.parse(data['tanggal']);
      _jumlahController.text = data['jumlah_bungkus'].toString();
      _hargaController.text = data['harga_satuan'].toString();
      _ketController.text = data['keterangan'] ?? '';
    });
  }

  void _hapusData(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'), content: const Text('Catatan pengeluaran makan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await DatabaseHelper.instance.deleteMakan(id);
              Navigator.pop(context); setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data dihapus!'), backgroundColor: Colors.red));
            }, child: const Text('Hapus'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Makan'), // JUDUL DIPERBARUI
        backgroundColor: Colors.orange[800], foregroundColor: Colors.white
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tanggal: ${DateFormat('dd MMM yyyy').format(_tanggalDipilih)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(context: context, initialDate: _tanggalDipilih, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (picked != null) setState(() => _tanggalDipilih = picked);
                          }, icon: const Icon(Icons.calendar_month, size: 18, color: Colors.orange), label: const Text('Ubah', style: TextStyle(color: Colors.orange)),
                        )
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _jumlahController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jml Bungkus', isDense: true))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _hargaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga/Bungkus', prefixText: 'Rp ', isDense: true))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _ketController, decoration: const InputDecoration(labelText: 'Keterangan (Misal: Makan Siang)', isDense: true)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_editId != null) Expanded(child: OutlinedButton(onPressed: _resetForm, child: const Text('BATAL', style: TextStyle(color: Colors.grey)))),
                        if (_editId != null) const SizedBox(width: 10),
                        Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _editId == null ? Colors.orange[800] : Colors.green[700], foregroundColor: Colors.white), onPressed: _simpanMakan, child: Text(_editId == null ? 'SIMPAN PENGELUARAN' : 'UPDATE DATA'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Align(alignment: Alignment.centerLeft, child: Text('Riwayat Pembelian Nasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.queryMakanByDate('2000-01-01', '2100-01-01'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Belum ada data makan.'));
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var m = snapshot.data![index];
                    DateTime tgl = DateTime.parse(m['tanggal']);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: _editId == m['id'] ? Colors.orange[50] : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.orange[100], child: Icon(Icons.fastfood, color: Colors.orange[800])),
                        title: Text('${m['jumlah_bungkus']} Bungkus (@${currencyFormatter.format(m['harga_satuan'])})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${DateFormat('dd MMM yyyy').format(tgl)} - ${m['keterangan']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(currencyFormatter.format(m['total_harga']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                            PopupMenuButton<String>(
                              onSelected: (value) { if (value == 'edit') _editData(m); if (value == 'hapus') _hapusData(m['id']); },
                              itemBuilder: (context) => [const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Edit Data')])), const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Hapus')]))],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}