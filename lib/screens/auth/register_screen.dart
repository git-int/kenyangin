import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// 1. Main Entry RegisterScreen (Layar Pilihan Akun)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E6DC)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFFC83E27), size: 10),
              SizedBox(width: 6),
              Text(
                'Kenyangin',
                style: TextStyle(
                  color: Color(0xFFC83E27),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 14,
                      color: Color(0xFFC83E27),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Good Food. Less Waste.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC83E27),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mulai Bergabung dengan\nKenyangin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih jenis akun yang sesuai dengan kebutuhan Anda untuk memulai.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Card Consumer
              _buildAccountCard(
                badgeText: 'Paling Populer',
                badgeColor: const Color(0xFFFFF0E6),
                badgeTextColor: const Color(0xFFC83E27),
                icon: Icons.shopping_bag_outlined,
                title: 'Consumer Account',
                description: 'Daftar untuk menemukan dan membeli makanan dengan harga lebih hemat.',
                tags: [
                  'Akses Surprise Bags',
                  'Diskon hingga 60%',
                  'Penyelamatan real-time',
                ],
                buttonText: 'Daftar sebagai Consumer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _RegisterConsumerScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Card Store
              _buildAccountCard(
                badgeText: 'Mitra Bisnis',
                badgeColor: const Color(0xFFE8F5E9),
                badgeTextColor: const Color(0xFF2E7D32),
                icon: Icons.storefront_outlined,
                title: 'Store Account',
                description: 'Daftar sebagai mitra toko dan mulai menjual produk makanan melalui Kenyangin.',
                tags: [
                  'Jual surplus makanan',
                  'Kurangi food waste',
                  'Dashboard analitik & QR pickup',
                ],
                buttonText: 'Daftar sebagai Store',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _RegisterStoreScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        color: Color(0xFFC83E27),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required String title,
    required String description,
    required List<String> tags,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFC83E27)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFFC83E27),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC83E27),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Formulir Registrasi Toko (Store Account)
class _RegisterStoreScreen extends StatefulWidget {
  const _RegisterStoreScreen();

  @override
  State<_RegisterStoreScreen> createState() => _RegisterStoreScreenState();
}

class _RegisterStoreScreenState extends State<_RegisterStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaPemilikController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _namaTokoController = TextEditingController();
  final _alamatTokoController = TextEditingController();
  final _noHpTokoController = TextEditingController();
  final _deskripsiTokoController = TextEditingController();

  String _selectedCategory = 'Bakery';
  bool _agreeTerms = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  final List<String> _categories = [
    'Bakery',
    'Restaurant',
    'Cafe',
    'Grocery',
    'Others',
  ];

  @override
  void dispose() {
    _namaPemilikController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _noHpTokoController.dispose();
    _deskripsiTokoController.dispose();
    super.dispose();
  }

  Future<void> _registerStore() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat dan Ketentuan.'),
        ),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().register(
        nama: _namaPemilikController.text.trim(),
        email: _emailController.text.trim(),
        noHp: _noHpController.text.trim(),
        password: _passwordController.text,
        role: 'toko',
        namaToko: _namaTokoController.text.trim(),
        alamatToko: _alamatTokoController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Pendaftaran Berhasil'),
          content: const Text(
            'Akun toko Anda berhasil dibuat! Silakan verifikasi email lalu login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, color: Color(0xFFC83E27), size: 16),
              SizedBox(width: 6),
              Text(
                'Pendaftaran Mitra Toko (Store)',
                style: TextStyle(
                  color: Color(0xFFC83E27),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Akun Store',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bergabung sebagai mitra F&B Kenyangin untuk mengelola surplus makanan dan raih pendapatan ekstra.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // SECTION A
                _buildSectionContainer(
                  title: 'A. Informasi Pemilik Akun',
                  subtitle: 'Data penanggung jawab usaha',
                  icon: Icons.person_outline,
                  children: [
                    _buildFieldLabel('Nama Pemilik Toko *'),
                    TextFormField(
                      controller: _namaPemilikController,
                      decoration: _inputDecoration('contoh Budi Santoso'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Email *'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('budi.owner@bakery.com'),
                      validator: (val) => val == null || !val.contains('@')
                          ? 'Email tidak valid'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Nomor Telepon *'),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Text(
                            'ID +62',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _noHpController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('811-2345-6789'),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Password *'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: _inputDecoration(
                        'Minimal 8 karakter unik',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? 'Minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Konfirmasi Password *'),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _hideConfirmPassword,
                      decoration: _inputDecoration(
                        'Ulangi password Anda',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _hideConfirmPassword = !_hideConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text)
                          return 'Password tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SECTION B
                _buildSectionContainer(
                  title: 'B. Informasi Toko',
                  subtitle: 'Detail gerai atau tempat usaha Anda',
                  icon: Icons.storefront,
                  children: [
                    _buildFieldLabel('Nama Toko *'),
                    TextFormField(
                      controller: _namaTokoController,
                      decoration: _inputDecoration('contoh Mom Bakery & Cafe'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Kategori Toko *'),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFFC83E27),
                          backgroundColor: const Color(0xFFF5F5F5),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Alamat Lengkap Toko *'),
                    TextFormField(
                      controller: _alamatTokoController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Jl. Tebet Barat Dalam No. 42, Tebet, Jakarta Selatan',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Nomor Telepon Toko *'),
                    TextFormField(
                      controller: _noHpTokoController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        '021-83701234 atau nomor operasional gerai',
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Deskripsi Singkat Toko'),
                    TextFormField(
                      controller: _deskripsiTokoController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Toko roti artisan dengan aneka pastry dan kue segar setiap hari',
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Foto Profil atau Logo Toko (opsional)'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFFC83E27),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unggah logo atau foto toko',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  'Format PNG, JPG maks 5MB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.upload,
                                    size: 14,
                                    color: Colors.black87,
                                  ),
                                  label: const Text(
                                    'Pilih Gambar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Checkbox Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      activeColor: const Color(0xFFC83E27),
                      onChanged: (val) =>
                          setState(() => _agreeTerms = val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat dan Ketentuan',
                                style: TextStyle(
                                  color: Color(0xFFC83E27),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                  color: Color(0xFFC83E27),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' Kemitraan Kenyangin.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _registerStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC83E27),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Daftar sebagai Store',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFFC83E27),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Eco Impact Banner Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.eco, color: Color(0xFF2E7D32)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Setiap kilogram makanan yang diselamatkan mengurangi jejak karbon bersama gerakan ramah lingkungan Kenyangin.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFC83E27), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey, size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC83E27), width: 1.5),
      ),
    );
  }
}

/// 3. Formulir Registrasi Konsumen (Sesuai Mockup Gambar Register Consumer)
class _RegisterConsumerScreen extends StatefulWidget {
  const _RegisterConsumerScreen();

  @override
  State<_RegisterConsumerScreen> createState() =>
      _RegisterConsumerScreenState();
}

class _RegisterConsumerScreenState extends State<_RegisterConsumerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerConsumer() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Syarat dan Ketentuan.'),
        ),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().register(
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        noHp: _noHpController.text.trim(),
        password: _passwordController.text,
        role: 'konsumen',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Registrasi Berhasil'),
          content: const Text('Akun konsumen berhasil dibuat. Silakan login.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E6DC)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFFC83E27), size: 10),
              SizedBox(width: 6),
              Text(
                'Kenyangin',
                style: TextStyle(
                  color: Color(0xFFC83E27),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Color(0xFFC83E27), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Consumer',
                    style: TextStyle(
                      color: Color(0xFFC83E27),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Akun Consumer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lengkapi data diri Anda untuk mulai berburu makanan lezat dan hemat pengeluaran.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 20),

                // 1. Nama Lengkap
                _buildFieldLabel('Nama Lengkap'),
                TextFormField(
                  controller: _namaController,
                  decoration: _inputDecoration(
                    'contoh Sarah Nabila',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),

                const SizedBox(height: 14),

                // 2. Email
                _buildFieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'sarah@email.com',
                    prefixIcon: Icons.alternate_email,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Email wajib diisi';
                    if (!val.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // 3. Nomor Telepon
                _buildFieldLabel('Nomor Telepon'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              width: 18,
                              height: 12,
                              color: Colors.red,
                              child: Column(
                                children: [
                                  Expanded(child: Container(color: Colors.red)),
                                  Expanded(
                                    child: Container(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+62',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('812-3456-7890'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Nomor telepon wajib diisi'
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Password
                _buildFieldLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: _inputDecoration(
                    'Minimal 8 karakter',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6
                      ? 'Password minimal 6 karakter'
                      : null,
                ),

                const SizedBox(height: 14),

                // 5. Konfirmasi Password
                _buildFieldLabel('Konfirmasi Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  decoration: _inputDecoration(
                    'Ulangi password',
                    prefixIcon: Icons.lock_reset,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text)
                      return 'Password tidak cocok';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Checkbox Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: const Color(0xFFC83E27),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) =>
                            setState(() => _agreeTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                          children: [
                            TextSpan(text: 'Saya menyetujui '),
                            TextSpan(
                              text: 'Syarat dan Ketentuan',
                              style: TextStyle(
                                color: Color(0xFFC83E27),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                color: Color(0xFFC83E27),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' Kenyangin.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tombol Daftar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _registerConsumer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC83E27),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider "atau daftar dengan"
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau daftar dengan',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  ],
                ),

                const SizedBox(height: 20),

                // Tombol Daftar dengan Google
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata_rounded,
                        size: 28,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Daftar dengan Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Link ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC83E27),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey, size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC83E27), width: 1.5),
      ),
    );
  }
}

