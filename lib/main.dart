import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/pekerja/pekerja_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Absensi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 1. Mengaktifkan Material 3
        useMaterial3: true, 
        
        // 2. Skema Warna
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber[700]!,
          primary: Colors.amber[800]!,
          secondary: Colors.blue[700]!,
          surface: Colors.grey[50]!, 
        ),

        // 3. Menggunakan Font Poppins
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        // 4. Desain AppBar
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),

        // 5. Desain Kartu (CardThemeData untuk versi Flutter terbaru)
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
        ),

        // 6. Desain Form Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, 
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        // 7. Desain Tombol
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      home: PekerjaList(),
    );
  }
}