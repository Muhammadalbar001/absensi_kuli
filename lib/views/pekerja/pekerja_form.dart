import 'package:flutter/material.dart';
import '../../models/pekerja.dart';
import '../../services/api_service.dart';

class PekerjaForm extends StatefulWidget {
  final Pekerja? pekerja; // Jika null = Tambah Baru, Jika terisi = Edit

  // Constructor
  PekerjaForm({this.pekerja});

  @override
  _PekerjaFormState createState() => _PekerjaFormState();
}

class _PekerjaFormState extends State<PekerjaForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _namaController;
  late TextEditingController _noHpController;
  late TextEditingController _posisiController;
  late TextEditingController _upahController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cek apakah ini mode Edit. Jika ya, isi kolom dengan data lama.
    bool isEdit = widget.pekerja != null;
    
    _namaController = TextEditingController(text: isEdit ? widget.pekerja!.nama : '');
    _noHpController = TextEditingController(text: isEdit ? widget.pekerja!.noHp : '');
    _posisiController = TextEditingController(text: isEdit ? widget.pekerja!.posisi : 'Kuli');
    _upahController = TextEditingController(text: isEdit ? widget.pekerja!.upahHarian.toString() : '');
  }

  void _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      bool sukses;
      
      // Jika mode EDIT, panggil editPekerja
      if (widget.pekerja != null) {
        sukses = await _apiService.editPekerja(
          widget.pekerja!.id,
          _namaController.text,
          _noHpController.text,
          _posisiController.text,
          int.parse(_upahController.text),
        );
      } 
      // Jika mode TAMBAH, panggil tambahPekerja
      else {
        sukses = await _apiService.tambahPekerja(
          _namaController.text,
          _noHpController.text,
          _posisiController.text,
          int.parse(_upahController.text),
        );
      }

      setState(() => _isLoading = false);

      if (sukses) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.pekerja != null ? 'Data berhasil diubah!' : 'Data berhasil ditambah!'), backgroundColor: Colors.green),
        );
      } else {
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
        backgroundColor: Colors.amber[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noHpController,
                decoration: InputDecoration(labelText: 'Nomor HP/WA', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _posisiController,
                decoration: InputDecoration(
                  labelText: 'Posisi/Keahlian', 
                  border: OutlineInputBorder(),
                  helperText: 'Contoh: Kenek, Tukang Batu, Tukang Kayu'
                ),
                validator: (value) => value!.isEmpty ? 'Posisi tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _upahController,
                decoration: InputDecoration(labelText: 'Upah Harian (Rp)', border: OutlineInputBorder(), prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Upah tidak boleh kosong' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'UPDATE DATA' : 'SIMPAN DATA', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}