import 'package:flutter/material.dart';
import '../../models/pekerja.dart';
import '../../services/db_helper.dart'; // MENGGUNAKAN OFFLINE DB

class PekerjaForm extends StatefulWidget {
  final Pekerja? pekerja;
  PekerjaForm({this.pekerja});

  @override
  _PekerjaFormState createState() => _PekerjaFormState();
}

class _PekerjaFormState extends State<PekerjaForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _noHpController;
  late TextEditingController _posisiController;
  late TextEditingController _upahController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    bool isEdit = widget.pekerja != null;
    
    _namaController = TextEditingController(text: isEdit ? widget.pekerja!.nama : '');
    _noHpController = TextEditingController(text: isEdit ? widget.pekerja!.noHp : '');
    _posisiController = TextEditingController(text: isEdit ? widget.pekerja!.posisi : 'Kuli');
    _upahController = TextEditingController(text: isEdit ? widget.pekerja!.upahHarian.toString() : '');
  }

  void _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, dynamic> rowData = {
        'nama': _namaController.text,
        'no_hp': _noHpController.text,
        'posisi': _posisiController.text,
        'upah_harian': int.parse(_upahController.text),
      };

      try {
        if (widget.pekerja != null) {
          rowData['id'] = widget.pekerja!.id;
          await DatabaseHelper.instance.updatePekerja(rowData);
        } else {
          await DatabaseHelper.instance.insertPekerja(rowData);
        }

        setState(() => _isLoading = false);
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.pekerja != null ? 'Data berhasil diubah!' : 'Data berhasil ditambah!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.pekerja != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Kuli' : 'Tambah Kuli Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noHpController,
                decoration: InputDecoration(labelText: 'Nomor HP/WA'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _posisiController,
                decoration: InputDecoration(
                  labelText: 'Posisi/Keahlian', 
                  helperText: 'Contoh: Kenek, Tukang Batu, Tukang Kayu'
                ),
                validator: (value) => value!.isEmpty ? 'Posisi tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _upahController,
                decoration: InputDecoration(labelText: 'Upah Harian (Rp)', prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Upah tidak boleh kosong' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'UPDATE DATA' : 'SIMPAN DATA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}