import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'views/dashboard/dashboard_page.dart'; // IMPORT BARU
import 'views/settings/settings_page.dart';   // IMPORT BARU
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
      
      // KODE BARU: MENDUKUNG DARK MODE & LIGHT MODE OTOMATIS
      themeMode: ThemeMode.system, // Ikuti pengaturan HP
      
      // Tema Terang (Light)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, primary: Colors.amber[800]!, secondary: Colors.teal),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true, elevation: 0, scrolledUnderElevation: 0,
          backgroundColor: Colors.amber[700], foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.amber, width: 2)),
        ),
      ),

      // Tema Gelap (Dark)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true, elevation: 0,
          backgroundColor: Colors.grey[900], foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: Colors.grey[850]),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.grey[800],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.amber, width: 2)),
        ),
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

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return DashboardPage(); // HALAMAN UTAMA BARU
      case 1: return PekerjaList();
      case 2: return AbsensiPage();
      case 3: return MakanPage();
      case 4: return RekapGlobalPage();
      case 5: return SettingsPage(); // PENGATURAN BARU
      default: return DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Menu navigasi bawah diperbanyak
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Kuli'),
          NavigationDestination(icon: Icon(Icons.assignment_turned_in_outlined), selectedIcon: Icon(Icons.assignment_turned_in), label: 'Absen'),
          NavigationDestination(icon: Icon(Icons.fastfood_outlined), selectedIcon: Icon(Icons.fastfood), label: 'Makan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Rekap'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Set'),
        ],
      ),
    );
  }
}