import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/pekerja/pekerja_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hitung Hari', // Nama aplikasi
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 1. Mengaktifkan Material 3 (Desain Android Terkini)
        useMaterial3: true,
        
        // 2. Skema Warna Amber yang Fresh
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.amber[800],
          secondary: Colors.teal,
          surface: const Color(0xFFF8F9FA), // Background aplikasi putih bersih keabuan
        ),

        // 3. Font Poppins Global
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

        // 4. AppBar Modern (Teks di tengah)
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, 
            fontWeight: FontWeight.w600, 
            color: Colors.white
          ),
        ),

        // 5. Desain Kartu (Rounded & Bayangan Halus)
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
        ),

        // 6. Transisi Halaman Mulus (Zoom & Fade)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),

        // 7. Desain Input Field
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
        ),
      ),
      home: PekerjaList(),
    );
  }
}