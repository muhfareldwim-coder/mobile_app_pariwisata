import 'package:flutter/material.dart';

export 'app.dart';
export 'presentation/pages/home_page.dart';

import 'app.dart';

void main() => runApp(const PariwisataApp());

// ---------------------------------------------------------------------------
// Palette — kept identical to the original tokens so nothing else breaks,
// plus a couple of extra neutrals used by the redesigned home screen.
// ---------------------------------------------------------------------------
class AppColors {
  static const paper = Color(0xFFF8FAFC);
  static const field = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const orange = Color(0xFFF58B05);
  static const yellow = Color(0xFFFFC22F);
  static const sky = Color(0xFFC4E9F2);
  static const blue = Color(0xFF7FBBDB);
  static const ink = Color(0xFF1F2937);
  static const dark = Color(0xFF1F2937);
  static const text = Color(0xFF64748B);
  static const muted = Color(0xFF64748B);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // extra neutrals for the home redesign (derived from the palette above)
  static const bg = Color(0xFFF4F6F9);
  static const cardBorder = Color(0xFFEDF1F5);
  static const blueDeep = Color(0xFF126080);
}

// ---------------------------------------------------------------------------
// LOGIN
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreed = false;
  bool _showAgreementError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  void _goHome() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  void _handleSubmit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _showAgreementError = !_agreed);
    if (formOk && _agreed) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'SISTEM INFORMASI DAN LAYANAN PARIWISATA\nKABUPATEN JEMBER',
          description: 'Masuk untuk menikmati informasi dan layanan\npariwisata Kabupaten Jember',
          fields: [
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Masukkan email yang valid'
                  : null,
            ),
            AppTextField(
              label: 'Password',
              hint: 'Masukkan password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (value) => value == null || value.length < 8
                  ? 'Password minimal 8 karakter'
                  : null,
              suffix: IconButton(
                tooltip: 'Tampilkan password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ],
          agreementSection: TermsAgreement(
            value: _agreed,
            showError: _showAgreementError,
            onChanged: (value) => setState(() {
              _agreed = value;
              if (value) _showAgreementError = false;
            }),
          ),
          buttonLabel: 'Masuk',
          onSubmit: _handleSubmit,
          secondaryAction: _goHome,
          secondaryLabel: 'Lanjutkan dengan Google',
          extraLink: TextButton(
            onPressed: () {},
            child: const Text(
              'Lupa password?',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
          footer: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
              children: [
                const TextSpan(text: 'Belum memiliki akun? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REGISTER
// ---------------------------------------------------------------------------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(4, (_) => TextEditingController());
  bool _agreed = false;
  bool _showAgreementError = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;

  void _handleSubmit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _showAgreementError = !_agreed);
    if (formOk && _agreed) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      form: Form(
        key: _formKey,
        child: AuthFormColumn(
          eyebrow: 'SISTEM INFORMASI DAN LAYANAN PARIWISATA\nKABUPATEN JEMBER',
          description: 'Daftar untuk mendapatkan akses ke layanan pariwisata\nKabupaten Jember',
          fields: [
            AppTextField(
              label: 'Nama Lengkap',
              hint: 'Nama lengkap',
              controller: _controllers[0],
              validator: _required,
            ),
            AppTextField(
              label: 'Nomor Telepon',
              hint: 'Contoh: 081234567890',
              controller: _controllers[1],
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _controllers[2],
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Masukkan email yang valid'
                  : null,
            ),
            AppTextField(
              label: 'Password',
              hint: 'Minimal 8 karakter',
              controller: _controllers[3],
              obscureText: true,
              validator: (value) => value == null || value.length < 8
                  ? 'Password minimal 8 karakter'
                  : null,
            ),
          ],
          agreementSection: TermsAgreement(
            value: _agreed,
            showError: _showAgreementError,
            onChanged: (value) => setState(() {
              _agreed = value;
              if (value) _showAgreementError = false;
            }),
          ),
          buttonLabel: 'Daftar',
          onSubmit: _handleSubmit,
          footer: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
              children: [
                const TextSpan(text: 'Sudah memiliki akun? '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox + label used on both Login and Register to confirm the user
/// accepts the Terms & Conditions / Privacy Policy before continuing.
class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final errorColor = showError ? AppColors.danger : AppColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(!value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: showError
                    ? Border.all(color: AppColors.danger.withValues(alpha: .4))
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: value,
                      onChanged: (v) => onChanged(v ?? false),
                      activeColor: AppColors.orange,
                      side: BorderSide(color: errorColor, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Saya telah membaca dan menyetujui ',
                            ),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: null,
                            ),
                            const TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: null,
                            ),
                            const TextSpan(text: ' JemberGo.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showError)
            const Padding(
              padding: EdgeInsets.only(left: 32, top: 2),
              child: Text(
                'Kamu harus menyetujui syarat & ketentuan terlebih dahulu',
                style: TextStyle(color: AppColors.danger, fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(color: Colors.white, child: form),
          ),
        ),
      ),
    );
  }
}

class AuthFormColumn extends StatelessWidget {
  const AuthFormColumn({
    super.key,
    required this.eyebrow,
    required this.description,
    required this.fields,
    required this.buttonLabel,
    required this.onSubmit,
    this.secondaryAction,
    this.secondaryLabel,
    required this.footer,
    this.extraLink,
    this.agreementSection,
  });
  final String eyebrow;
  final String description;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final VoidCallback? secondaryAction;
  final String? secondaryLabel;
  final Widget footer;
  final Widget? extraLink;
  final Widget? agreementSection;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BrandLogo()),
            const SizedBox(height: 48),
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ...fields.expand((field) => [field, const SizedBox(height: 14)]),
            if (agreementSection != null) ...[
              const SizedBox(height: 4),
              agreementSection!,
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            if (extraLink != null)
              Align(alignment: Alignment.centerRight, child: extraLink!),
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'atau',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: secondaryAction,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  label: Text(
                    secondaryLabel!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Center(child: footer),
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo_jembergonobackgroud.png',
      width: 620,
      height: 190,
      fit: BoxFit.contain,
    );
  }
}

class TravelPanel extends StatelessWidget {
  const TravelPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        bottomLeft: Radius.circular(28),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF55A9D0), Color(0xFF126080)],
              ),
            ),
          ),
          const Positioned(
            top: 28,
            right: 28,
            child: _GlassPill(
              icon: Icons.auto_awesome,
              text: 'Wonderful Jember',
            ),
          ),
          const Positioned(
            left: 28,
            bottom: 32,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassPill(
                  icon: Icons.location_on,
                  text: 'Kabupaten Jember, Jawa Timur',
                ),
                SizedBox(height: 18),
                Text(
                  'Jelajahi pesona\nJember.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Pantai, perbukitan hijau, dan pengalaman wisata yang menunggu untuk ditemukan.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      border: Border.all(color: Colors.white.withValues(alpha: .3)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// HOME — redesigned to read as a polished OTA-style app (Traveloka-esque):
// clearer hierarchy, a real search bar, consistent card elevation/radius,
// badge-style ratings and prices, and tighter spacing rhythm throughout.
// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            _HomeHeader(onLogout: () => _logout(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _ExploreBanner(),
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Kategori Wisata',
                    action: 'Semua',
                    subtitle: 'Pilih ragam destinasi unggulan',
                  ),
                  const SizedBox(height: 12),
                  const _CategoryRow(),
                  const SizedBox(height: 22),
                  const _FeatureTabs(),
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Destinasi Populer',
                    action: 'Lihat Semua',
                    subtitle: 'Paling banyak dikunjungi wisatawan pekan ini',
                  ),
                  const SizedBox(height: 12),
                  const _PopularDestinations(),
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Destinasi Terdekat',
                    action: 'Semua',
                    subtitle: 'Rekomendasi terdekat dari lokasimu',
                  ),
                  const SizedBox(height: 12),
                  const _NearbyList(),
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: 'Berita & Panduan Wisata',
                    action: 'Lihat Semua',
                    subtitle: 'Informasi acara, akses, & tips berwisata',
                  ),
                  const SizedBox(height: 12),
                  const _ArticleCard(
                    icon: Icons.directions_bus,
                    label: 'Transportasi & Acara',
                    title: 'Jadwal & Rute Shuttle Wisata Jember Fashion Carnival (JFC) 2026',
                    color: Color(0xFF0E6658),
                  ),
                  const SizedBox(height: 12),
                  const _ArticleCard(
                    icon: Icons.tips_and_updates,
                    label: 'Tips & Panduan',
                    title: '5 Panduan Booking Homestay & Destinasi Wisata Tanpa Boncos',
                    color: AppColors.orange,
                  ),
                  const SizedBox(height: 26),
                  const _HomeFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _HomeNavigation(),
    );
  }

  void _logout(BuildContext context) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.blueDeep],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset(
                  'assets/logo_jembergonobackgroud.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JELAJAH JEMBER',
                      style: TextStyle(
                        color: AppColors.sky,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Halo, Petualang! 🌿',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(icon: Icons.favorite_border, onPressed: () {}),
              const SizedBox(width: 4),
              _HeaderIconButton(
                icon: Icons.notifications_none,
                onPressed: () {},
                showDot: true,
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(24),
                child: const CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.yellow,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.text, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cari pantai, air terjun, bukit...',
                          style: TextStyle(color: AppColors.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withValues(alpha: .4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune, color: AppColors.dark, size: 21),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.showDot = false,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          if (showDot)
            const Positioned(
              top: 9,
              right: 10,
              child: CircleAvatar(
                radius: 3.5,
                backgroundColor: AppColors.orange,
              ),
            ),
        ],
      ),
    ),
  );
}

class _ExploreBanner extends StatelessWidget {
  const _ExploreBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 168,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.blueDeep, AppColors.orange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.orange.withValues(alpha: .28),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -30,
          bottom: -30,
          child: Icon(
            Icons.landscape,
            size: 150,
            color: Colors.white.withValues(alpha: .10),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassPill(icon: Icons.location_on, text: 'Kab. Jember'),
                  SizedBox(height: 12),
                  Text(
                    'EKSPLORASI EKSOTIS',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pesona Kota Karnaval,\nTembakau & Surga Selatan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Positioned(left: 0, bottom: 0, child: _BannerButton()),
      ],
    ),
  );
}

class _BannerButton extends StatelessWidget {
  const _BannerButton();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Jelajahi Sekarang',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 15, color: AppColors.orange),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.subtitle,
  });
  final String title;
  final String action;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.text, fontSize: 11),
            ),
          ],
        ),
      ),
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Row(
          children: [
            Text(
              action,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.orange, size: 17),
          ],
        ),
      ),
    ],
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();
  @override
  Widget build(BuildContext context) => Row(
    children: const [
      _Category(
        icon: Icons.terrain,
        name: 'Alam',
        count: '14 Destinasi',
        selected: true,
      ),
      _Category(
        icon: Icons.waves,
        name: 'Bahari',
        count: '8 Pantai',
        selected: false,
      ),
      _Category(
        icon: Icons.account_balance,
        name: 'Buatan',
        count: '12 Wahana',
        selected: false,
      ),
    ],
  );
}

class _Category extends StatelessWidget {
  const _Category({
    required this.icon,
    required this.name,
    required this.count,
    required this.selected,
  });
  final IconData icon;
  final String name;
  final String count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF0E7A66), Color(0xFF0D6657)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          border: selected ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (selected ? const Color(0xFF0D6657) : Colors.black)
                  .withValues(alpha: selected ? .22 : .05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .18)
                    : AppColors.orange.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.orange,
                size: 18,
              ),
            ),
            const Spacer(),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.dark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              count,
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.text,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTabs extends StatelessWidget {
  const _FeatureTabs();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 10),
      ],
    ),
    child: Row(
      children: const [
        _Feature(
          icon: Icons.map_outlined,
          label: 'Peta',
          color: AppColors.blueDeep,
        ),
        _Feature(
          icon: Icons.confirmation_num_outlined,
          label: 'Tiket',
          color: AppColors.orange,
        ),
        _Feature(
          icon: Icons.favorite,
          label: 'Populer',
          color: Color(0xFFEF4463),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularDestinations extends StatelessWidget {
  const _PopularDestinations();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 240,
    child: ListView(
      scrollDirection: Axis.horizontal,
      primary: false,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      children: const [
        _DestinationCard(
          title: 'Pantai Tanjung Papuma',
          location: 'Wuluhan, Jember',
          rating: '4.9',
          reviews: '3.1k',
          price: 'Rp 25.000',
          badge: 'Bahari',
          color: Color(0xFF2C7A9E),
          icon: Icons.waves,
        ),
        _DestinationCard(
          title: 'Teluk Love Payangan',
          location: 'Ambulu, Jember',
          rating: '4.8',
          reviews: '2.4k',
          price: 'Rp 20.000',
          badge: 'Bahari',
          color: Color(0xFF4C7A63),
          icon: Icons.landscape,
        ),
      ],
    ),
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.title,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.badge,
    required this.color,
    required this.icon,
  });
  final String title;
  final String location;
  final String rating;
  final String reviews;
  final String price;
  final String badge;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: .75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: .82),
                    size: 46,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 11,
                          color: AppColors.yellow,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$rating  •  $reviews',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mulai dari',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 8.5,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              color: AppColors.blueDeep,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyList extends StatelessWidget {
  const _NearbyList();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _NearbyItem(
        icon: Icons.water,
        title: 'Pemandian Patemon',
        type: 'Buatan',
        location: 'Tanggul, Kab. Jember',
        distance: '4.2 km',
        price: 'Rp 15.000',
      ),
      _NearbyItem(
        icon: Icons.waterfall_chart,
        title: 'Dira Park Ambulu',
        type: 'Buatan',
        location: 'Ambulu, Kab. Jember',
        distance: '6.5 km',
        price: 'Rp 20.000',
      ),
      _NearbyItem(
        icon: Icons.terrain,
        title: 'Air Terjun Tancak',
        type: 'Alam',
        location: 'Panti, Kab. Jember',
        distance: '12.0 km',
        price: 'Rp 10.000',
      ),
    ],
  );
}

class _NearbyItem extends StatelessWidget {
  const _NearbyItem({
    required this.icon,
    required this.title,
    required this.type,
    required this.location,
    required this.distance,
    required this.price,
  });
  final IconData icon;
  final String title;
  final String type;
  final String location;
  final String distance;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.blueDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sky,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: AppColors.blueDeep,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(color: AppColors.text, fontSize: 9),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.star, size: 11, color: AppColors.orange),
                    SizedBox(width: 2),
                    Text(
                      '4.7  (1.1k ulasan)',
                      style: TextStyle(color: AppColors.text, fontSize: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me, size: 11, color: AppColors.text),
                  const SizedBox(width: 3),
                  Text(
                    distance,
                    style: const TextStyle(color: AppColors.text, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.blueDeep,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: .7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: .85),
                size: 34,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        '5 menit baca',
                        style: TextStyle(color: AppColors.muted, fontSize: 8.5),
                      ),
                      const Spacer(),
                      Text(
                        'Baca →',
                        style: TextStyle(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.dark, AppColors.blueDeep],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/logo_jembergonobackgroud.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JemberGo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Pariwisata Terpadu Kab. Jember',
                  style: TextStyle(color: Colors.white70, fontSize: 8.5),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Platform pariwisata digital terintegrasi untuk Kabupaten Jember, Jawa Timur.',
          style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.6),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tentang Jember Go',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Bantuan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kebijakan Privasi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 4),
        const Text(
          '© 2026 JEMBER GO — Dinas Pariwisata Kabupaten Jember',
          style: TextStyle(color: Colors.white54, fontSize: 8.5),
        ),
      ],
    ),
  );
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Eksplor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            activeIcon: Icon(Icons.confirmation_num),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    ),
  );
}
