import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import semua halaman utama
import 'views/pekerja/pekerja_list.dart';
import 'views/absensi/absensi_page.dart';
import 'views/pekerja/makan_page.dart';
import 'views/pekerja/rekap_global_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hitung Hari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.amber[800]!,
          secondary: Colors.teal,
          surface: const Color(0xFFF8F9FA),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true, 
          elevation: 0, 
          scrolledUnderElevation: 0,
          backgroundColor: Colors.amber[700], 
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(), 
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // KODE BARU: Memuat halaman secara dinamis agar selalu refresh saat tab ditekan
  Widget _buildPage(int index) {
    switch (index) {
      case 0: return PekerjaList();
      case 1: return AbsensiPage();
      case 2: return MakanPage();
      case 3: return RekapGlobalPage();
      default: return PekerjaList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // KODE BARU: Mengganti IndexedStack dengan pemanggilan fungsi buildPage
      body: _buildPage(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Memicu refresh halaman
          });
        },
        indicatorColor: Colors.amber[200],
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Kuli'),
          NavigationDestination(icon: Icon(Icons.assignment_turned_in_outlined), selectedIcon: Icon(Icons.assignment_turned_in), label: 'Absen'),
          NavigationDestination(icon: Icon(Icons.fastfood_outlined), selectedIcon: Icon(Icons.fastfood), label: 'Makan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Rekap'),
        ],
      ),
    );
  }
}