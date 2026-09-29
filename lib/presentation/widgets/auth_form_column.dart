import 'package:flutter/material.dart';

import 'brand_logo.dart';

class AuthFormColumn extends StatelessWidget {
  const AuthFormColumn({
    super.key,
    required this.eyebrow,
    required this.description,
    required this.fields,
    required this.buttonLabel,
    required this.onSubmit,
    required this.isRegister,
    required this.googleAction,
    required this.guestAction,
    required this.switchAction,
    required this.switchLabel,
    this.forgotAction,
    this.agreementSection,
    this.loginOptions,
  });

  final String eyebrow;
  final String description;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final bool isRegister;
  final VoidCallback googleAction;
  final VoidCallback guestAction;
  final VoidCallback switchAction;
  final String switchLabel;
  final VoidCallback? forgotAction;
  final Widget? agreementSection;
  final Widget? loginOptions;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102F50);
    const blue = Color(0xFF1265B8);
    const muted = Color(0xFF6F7785);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRegister)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: navy),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(
                      color: navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.account_circle_outlined, color: navy),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(24, isRegister ? 20 : 34, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFEBEEFF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x160D2744),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const BrandLogo(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_outlined, size: 15, color: blue),
                      const SizedBox(width: 7),
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isRegister
                      ? 'Daftar Akun JemberGo'
                      : 'Selamat Datang di JemberGo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...fields.expand(
                  (field) => [field, const SizedBox(height: 14)],
                ),
                if (loginOptions != null || forgotAction != null)
                  Row(
                    children: [
                      if (loginOptions != null) Expanded(child: loginOptions!),
                      if (forgotAction != null)
                        TextButton(
                          onPressed: forgotAction,
                          style: TextButton.styleFrom(
                            foregroundColor: blue,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          child: const Text('Lupa Kata Sandi?'),
                        ),
                    ],
                  ),
                if (agreementSection != null) ...[
                  const SizedBox(height: 2),
                  agreementSection!,
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 19),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFFD9DEEA))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ATAU MASUK DENGAN',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFD9DEEA))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: googleAction,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    label: Text(
                      isRegister
                          ? 'Daftar Cepat dengan Google'
                          : 'Masuk dengan Akun Google',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFDCE3F4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: guestAction,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDCE3F4)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5EAFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.explore_outlined,
                                color: blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jelajahi Dulu Tanpa Login',
                                    style: TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'MODE TAMU / PENGUNJUNG',
                                    style: TextStyle(
                                      color: blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF7B8492),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: Color(0xFFEDF0F6)),
                        ),
                        const Text(
                          'Anda dapat melihat destinasi dan info wisata. Login wajib saat melakukan pemesanan tiket wisata.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isRegister
                            ? 'Sudah punya akun? '
                            : 'Belum punya akun JemberGo? ',
                        style: const TextStyle(color: muted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: switchAction,
                        style: TextButton.styleFrom(
                          foregroundColor: blue,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Text(
                          switchLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_outlined, color: navy, size: 18),
                      SizedBox(height: 4),
                      Text(
                        'DINAS PARIWISATA DAN KEBUDAYAAN',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aplikasi Resmi Pariwisata Kabupaten Jember',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
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
