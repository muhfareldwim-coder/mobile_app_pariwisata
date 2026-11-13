import 'package:flutter/material.dart';

import '../../data/services/language_preference_service.dart';

class AppTranslations {
  static const _english = <String, String>{
    'Detail Artikel': 'Article Details',
    'Dipublikasikan ': 'Published ',
    'Artikel Wisata': 'Travel Articles',
    'Belum ada artikel yang dipublikasikan.':
        'No articles have been published yet.',
    'Kirim ulang kode OTP': 'Resend OTP',
    'Ingat Saya': 'Remember Me',
    'Masuk untuk menikmati informasi dan layanan pariwisata Kabupaten Jember':
        'Sign in to enjoy tourism information and services in Jember Regency.',
    'Masuk dengan Google': 'Sign in with Google',
    'atau': 'or',
    'Lupa password?': 'Forgot password?',
    'Buat password baru': 'Create a new password',
    'Kirim kode OTP': 'Send OTP',
    'Simpan password': 'Save Password',
    'Konfirmasi password tidak sama.': 'Passwords do not match.',
    'Masukkan kode OTP 6 digit.': 'Enter the 6-digit OTP.',
    'Password minimal 8 karakter.': 'Password must be at least 8 characters.',
    'Masukkan email yang valid': 'Enter a valid email address.',
    'Konfirmasi kata sandi tidak sama': 'Passwords do not match.',
    'Nama ketua': 'Leader Name',
    'Nama anggota': 'Member Name',
    'Peserta': 'Participant',
    'Ketua kelompok': 'Group Leader',
    'Jenis tiket.': 'Ticket type.',
    'Memeriksa sisa tiket...': 'Checking ticket availability...',
    'Pilih tanggal untuk melihat sisa tiket.':
        'Select a date to check ticket availability.',
    'Sisa tiket akan diperiksa saat pesanan dikirim.':
        'Ticket availability will be checked when you submit the booking.',
    'Destinasi ini tidak menerapkan batas kuota tiket.':
        'This destination does not have a ticket quota limit.',
    'Cek ulang': 'Check Again',
    'Konfirmasi kata sandi tidak sama.': 'Passwords do not match.',
    'Nomor telepon': 'Phone Number',
    'Nomor Telepon': 'Phone Number',
    'Tidak ada tiket aktif': 'No active tickets',
    'Tidak ada riwayat tiket': 'No ticket history',
    'Artikel gagal dimuat': 'Could not load articles',
    'Tanggal': 'Date',
    'Status': 'Status',
    'Lihat Semua': 'See All',
    'Simpan favorit': 'Save to Favorites',
    'Hapus favorit': 'Remove from Favorites',
    'Tulis ulasan': 'Write a review',
    'Buka e-tiket': 'Open e-ticket',
    'Masukkan nomor telepon': 'Enter phone number',
    'Nama wajib diisi': 'Name is required.',
    'Nama maksimal 150 karakter.': 'Name must be 150 characters or fewer.',
    'Ulasan tidak boleh kosong.': 'A review is required.',
    'Pilih jenis tiket.': 'Select a ticket type.',
    'Pilih tanggal kunjungan': 'Select a visit date',
    'Pilih': 'Select',
    'Lanjut': 'Continue',
    'Muat ulang': 'Reload',
    'Filter': 'Filter',
    'Semua': 'All',
    'ALAM': 'NATURE',
    'BAHARI': 'COASTAL',
    'BUATAN': 'MAN-MADE',
    'Nama Lengkap': 'Full Name',
    'Nama lengkap': 'Full name',
    'Masukkan Nomor Telepon': 'Enter phone number',
    'Masukkan Email': 'Enter email',
    'Kata Sandi': 'Password',
    'Masukkan password': 'Enter password',
    'Minimal 8 karakter': 'At least 8 characters',
    'Password baru': 'New Password',
    'Konfirmasi password': 'Confirm Password',
    'Ulangi password baru': 'Re-enter new password',
    'Kode OTP': 'OTP Code',
    '6 digit': '6 digits',
    'Total peserta': 'Total Participants',
    'Total dibayar': 'Total Paid',
    'Masukkan kode 6 digit yang dikirim ke ': 'Enter the 6-digit code sent to ',
    '. Kode berlaku selama 10 menit.': '. The code is valid for 10 minutes.',
    'Verifikasi OTP': 'Verify OTP',
    'Mengirim ulang kode...': 'Resending code...',
    'Fitur ini belum tersedia.': 'This feature is not available yet.',
    'Jenis tiket destinasi belum tersedia.':
        'Ticket types are not available for this destination yet.',
    'Pilih tanggal kunjungan terlebih dahulu.':
        'Please select a visit date first.',
    'Pilih jenis tiket ketua terlebih dahulu.':
        'Please select the group leader’s ticket type first.',
    'Lengkapi nama dan jenis tiket semua anggota.':
        'Enter the name and ticket type for every member.',
    'Pilihan tiket belum tersedia dari server.':
        'Ticket options are not available from the server yet.',
    'Peserta terisi': 'Participants',
    ' orang': ' people',
    'Tambah anggota': 'Add member',
    'Pemesanan Tiket': 'Book Tickets',
    'Tanggal kunjungan wajib dipilih.': 'A visit date is required.',
    'Jenis Tiket': 'Ticket Type',
    'Pilih jenis tiket': 'Select a ticket type',
    'Rincian Pembayaran': 'Payment Details',
    'Total Tagihan': 'Total Due',
    'Total Pembayaran': 'Total Payment',
    'Lanjut Bayar': 'Continue to Payment',
    'Data Peserta': 'Participant Details',
    'Checkout': 'Checkout',
    ' tiket\nTanggal: ': ' tickets\nDate: ',
    'Ringkasan pesanan': 'Order Summary',
    'Pembayaran': 'Payment',
    'Rincian peserta': 'Participant Details',
    'Pembayaran diproses dengan aman': 'Your payment is processed securely',
    'Data pesananmu tercatat dan e-ticket akan diterbitkan setelah pembayaran berhasil dikonfirmasi.': 'Your order has been recorded. Your e-ticket will be issued once your payment is confirmed.',
    'Selesaikan pembayaran': 'Complete Payment',
    'Kode pembayaran tidak dapat dimuat. Periksa koneksi lalu coba lagi.': 'The payment code could not be loaded. Check your connection and try again.',
    'Buka aplikasi pembayaran yang mendukung, lalu pindai kode di atas.':
        'Open a supported payment app and scan the code above.',
    'Tautan Midtrans berhasil disalin.': 'Midtrans link copied.',
    'Tautan Midtrans gagal disalin.': 'Could not copy the Midtrans link.',
    'Salin tautan Midtrans': 'Copy Midtrans Link',
    'Cara pembayaran': 'How to Pay',
    'Pembayaran diproses dengan aman. Status transaksi diperiksa kembali ke server dan e-ticket diterbitkan setelah pembayaran dikonfirmasi.': 'Your payment is processed securely. The transaction status is verified with the server, and your e-ticket is issued after confirmation.',
    'Galeri destinasi belum tersedia.':
        'The destination gallery is not available yet.',
    'Foto tidak tersedia': 'Photo unavailable',
    'Belum ada ulasan.': 'No reviews yet.',
    ' foto': ' photos',
    'Rating': 'Rating',
    'Belum tersedia.': 'Not available yet.',
    'Menghitung rute...': 'Calculating route...',
    'Harga tiket mulai': 'Tickets from',
    'Ulas ': 'Review ',
    'Rating Anda': 'Your Rating',
    'Batal': 'Cancel',
    'Kirim ulasan': 'Submit Review',
    'Daftar Wisata': 'Destinations',
    'Temukan destinasi wisata yang sesuai dengan keinginanmu':
        'Find a destination that suits you',
    'Sedang mempersiapkan wisata...': 'Loading destinations...',
    'Coba lagi': 'Try Again',
    'Destinasi tidak ditemukan': 'No destinations found',
    'Jelajahi Wisata': 'Explore Destinations',
    'Cari pantai, alam, atau tempat seru lainnya.':
        'Search for beaches, nature, and other great places.',
    'Filter destinasi': 'Filter Destinations',
    'Kategori': 'Category',
    'Urutkan': 'Sort',
    'Tampilkan destinasi': 'Show Destinations',
    'Destinasi gagal dimuat: ': 'Could not load destinations: ',
    'Belum ada wisata populer.': 'No popular destinations yet.',
    'Belum ada wisata terdekat.': 'No nearby destinations yet.',
    'Selamat datang, ': 'Welcome, ',
    'PESONA KABUPATEN JEMBER': 'THE CHARM OF JEMBER REGENCY',
    'Jember, selalu punya cerita': 'Jember always has a story to tell',
    'Pantai, alam, dan budaya menantimu.':
        'Beaches, nature, and culture are waiting for you.',
    'Jelajahi Destinasi': 'Explore Destinations',
    'Artikel gagal dimuat: ': 'Could not load articles: ',
    'Mulai dari': 'Starting from',
    ' km': ' km',
    'Peta Wisata': 'Tourist Map',
    'Temukan dan pilih destinasi wisata Jember.':
        'Find and choose destinations in Jember.',
    ' dari ': ' of ',
    'Pilih destinasi': 'Select a destination',
    'Menghitung...': 'Calculating...',
    'Mulai ulang': 'Restart',
    'Simpan': 'Save',
    'Edit Profil': 'Edit Profile',
    'Keluar Akun': 'Sign Out',
    'Kamu yakin ingin keluar dari akun JemberGo?':
        'Are you sure you want to sign out of JemberGo?',
    'Keluar': 'Sign Out',
    'Pilihan Bahasa': 'Language',
    'Tutup': 'Close',
    'Profil': 'Profile',
    'Beranda': 'Home',
    'Jelajah': 'Explore',
    'Peta': 'Map',
    'Tiket': 'Tickets',
    'WISATA FAVORIT': 'FAVORITE DESTINATIONS',
    'PUSAT INFORMASI': 'INFORMATION',
    'Kelola akun dan preferensi wisatamu.':
        'Manage your account and travel preferences.',
    'Masuk untuk memesan tiket dan menyimpan destinasi favoritmu.':
        'Sign in to book tickets and save your favorite destinations.',
    'Masuk': 'Sign In',
    'Daftar': 'Register',
    'Nikmati Kemudahan Berwisata Bersama JemberGo':
        'Enjoy Easier Travel with JemberGo',
    'Destinasi yang kamu simpan akan muncul di sini.':
        'Your saved destinations will appear here.',
    'Dinas Pariwisata & Kebudayaan Kabupaten\nJember, Jawa Timur':
        'Tourism and Culture Office of Jember Regency\nEast Java',
    'Perubahan perjalanan berhasil disimpan.':
        'Trip changes saved successfully.',
    'Tinjau perubahan': 'Review Changes',
    'Destinasi: ': 'Destination: ',
    'Tanggal kunjungan: ': 'Visit date: ',
    'Anggota tambahan:': 'Additional members:',
    '• ': '• ',
    'Biaya tambahan: ': 'Additional cost: ',
    'Periksa lagi': 'Review Again',
    'Kelola perjalanan': 'Manage Trip',
    'Tanggal kunjungan baru': 'New Visit Date',
    'Booking sudah penuh\nJumlah peserta saat ini sudah mencapai 10 orang.':
        'Booking is full\nThe current booking already has 10 participants.',
    ' slot tiket tersedia · maksimal 10 orang per pemesanan.':
        ' ticket slots available · up to 10 people per booking.',
    'Memproses perubahan...': 'Processing changes...',
    'Lunas': 'Paid',
    ' peserta': ' participants',
    ' dibayar': ' paid',
    'Ada perubahan yang belum selesai': 'There are pending changes',
    'Anggota ': 'Member ',
    'Total biaya tambahan': 'Total Additional Cost',
    'Muat ulang tiket': 'Reload Tickets',
    'Tiket Saya': 'My Tickets',
    'Kelola tiket dan pesanan perjalananmu.':
        'Manage your tickets and trip bookings.',
    'Jember': 'Jember',
    'Tambahkan ke favorit': 'Add to Favorites',
    'Tambah ke favorit': 'Add to Favorites',
    'Alam': 'Nature',
    'Bahari': 'Coastal',
    'Buatan': 'Man-made',
    'Wisata': 'Destination',
    'Menunggu pembayaran': 'Awaiting Payment',
    'Batalkan pesanan': 'Cancel booking',
    'Batalkan pesanan?': 'Cancel booking?',
    'Pesanan ini akan dibatalkan dan tidak dapat dilanjutkan kembali.':
        'This booking will be cancelled and cannot be resumed.',
    'Tidak, kembali': 'No, go back',
    'Ya, batalkan pesanan': 'Yes, cancel booking',
    'Pesanan berhasil dibatalkan.': 'Booking cancelled successfully.',
    'Pesanan hanya dapat dibatalkan sebelum pembayaran dimulai.':
        'A booking can only be cancelled before payment begins.',
    'ID pesanan tidak valid.': 'The booking ID is invalid.',
    'Dibatalkan': 'Cancelled',
    'Sudah digunakan': 'Used',
    'Sebagian digunakan': 'Partially Used',
    'Kadaluarsa': 'Expired',
    'Belum diproses': 'Not Processed',
    'Belum ada tiket aktif': 'No active tickets yet',
    'Belum ada riwayat tiket': 'No ticket history yet',
    'Belum ada pesanan': 'No bookings yet',
    'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional (maksimal 15 digit).': 'Use 10–12 local digits or start with + for an international number (up to 15 digits).',
    'Email harus menggunakan alamat @gmail.com.':
        'Use a @gmail.com email address.',
    'Nama hanya boleh berisi huruf dan spasi (maksimal 100 karakter)':
        'Name can only contain letters and spaces (up to 100 characters).',
    'Gunakan 10-12 digit lokal atau awali + untuk nomor internasional':
        'Use 10–12 local digits or start with + for an international number.',
    'Password minimal 8 karakter': 'Password must be at least 8 characters.',
    'Gunakan password minimal 8 karakter.':
        'Use a password with at least 8 characters.',
    'Kata sandi baru minimal 8 karakter':
        'The new password must be at least 8 characters.',
    'Nama': 'Name',
    'Kode ': 'Code ',
    'E-ticket': 'E-ticket',
    'Bayar': 'Pay',
    'Detail E-Tiket': 'E-Ticket Details',
    'Beri Review': 'Leave a Review',
    'Kode booking disalin.': 'Booking code copied.',
    'Bagaimana pengalamanmu di destinasi ini?':
        'How was your experience at this destination?',
    'Kirim': 'Submit',
    'Terima kasih, review berhasil dikirim.':
        'Thank you. Your review has been submitted.',
    'PDF e-tiket berhasil disimpan.': 'E-ticket PDF saved.',
    'PDF e-tiket gagal disimpan: ': 'Could not save e-ticket PDF: ',
    'Tunjukkan kode booking kepada petugas saat tiba di destinasi.':
        'Show your booking code to staff when you arrive at the destination.',
    'Unduh PDF': 'Download PDF',
    'Kode QR booking': 'Booking QR Code',
    'Satu kode QR untuk seluruh peserta dalam booking ini.':
        'One QR code for all participants in this booking.',
    'KODE BOOKING': 'BOOKING CODE',
    'ATAU': 'OR',
    'Jelajahi sebagai tamu': 'Continue as Guest',
    'Kamu harus menyetujui syarat & ketentuan terlebih dahulu':
        'You must agree to the terms and conditions first.',
    'Saya menyetujui syarat dan ketentuan':
        'I agree to the terms and conditions',
    'Notifikasi': 'Notifications',
    'Kategori Wisata': 'Categories',
    'Pilih ragam destinasi unggulan': 'Discover featured destinations',
    'Destinasi Populer': 'Popular Destinations',
    'Paling banyak mendapat ulasan wisatawan': 'Most reviewed by travelers',
    'Destinasi Terdekat': 'Nearby Destinations',
    'Artikel Terbaru': 'Latest Articles',
    'Baca artikel terbaru seputar wisata Jember.':
        'Read the latest articles about travel in Jember.',
    'Kembali': 'Back',
    'Tentang Destinasi': 'About this Destination',
    'Lokasi & rute': 'Location & Directions',
    'Fasilitas': 'Facilities',
    'Jenis tiket': 'Ticket Types',
    'Ulasan pengunjung': 'Visitor Reviews',
    'Terima kasih! Ulasan Anda sudah tercatat sebagai pengunjung terverifikasi.':
        'Thank you! Your review has been recorded as a verified visitor.',
    'Tiket Anda sudah digunakan. Bagikan pengalaman wisata Anda.':
        'Your ticket has been used. Share your travel experience.',
    'Rating dan ulasan tersedia setelah tiket digunakan pada hari kunjungan.': 'Ratings and reviews are available after your ticket is used on the visit date.',
    'Tutup galeri': 'Close Gallery',
    'Ceritakan pengalaman Anda': 'Tell us about your experience',
    'Tulis ulasanmu': 'Write your review',
    'Salin kode booking': 'Copy Booking Code',
    'Syarat Ketentuan & Kebijakan Privasi': 'Terms & Privacy Policy',
    'Informasi syarat dan kebijakan': 'Terms and policy information',
    'Tentang JemberGo': 'About JemberGo',
    'Informasi aplikasi': 'App information',
    'Informasi syarat dan kebijakan akan ditambahkan di sini.':
        'Terms and policy information will be added here.',
    'Informasi tentang JemberGo akan ditambahkan di sini.':
        'Information about JemberGo will be added here.',
    'Edit profil': 'Edit profile',
    'Hapus dari favorit': 'Remove from favorites',
    'Informasi pribadi': 'Personal Information',
    'Pastikan data yang digunakan untuk pemesanan selalu benar.':
        'Make sure your booking information is always up to date.',
    'Keamanan akun': 'Account Security',
    'Gunakan minimal 8 karakter. Kosongkan jika tidak ingin mengubahnya.': 'Use at least 8 characters. Leave blank if you do not want to change it.',
    'Hapus pencarian': 'Clear Search',
    'Tutup filter': 'Close Filters',
    'Muat ulang destinasi': 'Reload Destinations',
    'Cari wisata yang anda inginkan': 'Search for a destination',
    'Cari destinasi yang anda inginkan': 'Search for a destination',
    'Pilih destinasi wisata': 'Select a destination',
    'Nama lengkap peserta': 'Participant Full Name',
    'Gagal': 'Failed',
    'Kedaluwarsa': 'Expired',
    'Belum dibayar': 'Unpaid',
    'Hapus anggota': 'Remove Member',
    'Hapus peserta ': 'Remove Participant ',
    'Lihat detail': 'View Details',
    'Judul': 'Title',
    'Tidak ada foto': 'No photo available',
    'Jika email terdaftar, kode OTP telah dikirim.':
        'If the email is registered, an OTP has been sent.',
    'Verifikasi OTP tidak tersedia. Mulai ulang proses reset password.':
        'OTP verification is unavailable. Restart the password reset process.',
    'Masukkan email akun Anda untuk menerima kode OTP.':
        'Enter your account email to receive an OTP.',
    'Masukkan email yang valid.': 'Enter a valid email address.',
    'Login Google tersedia melalui aplikasi Android atau iOS.':
        'Google sign-in is available in the Android or iOS app.',
    'Google tidak mengembalikan token akun. Periksa konfigurasi OAuth aplikasi.': 'Google did not return an account token. Check the app OAuth configuration.',
    'Password berhasil diubah. Silakan masuk kembali.':
        'Password changed successfully. Please sign in again.',
    'Email berhasil diverifikasi. Silakan masuk.':
        'Email verified successfully. Please sign in.',
    'Kode OTP baru telah dikirim.': 'A new OTP has been sent.',
    'Verifikasi akun Google': 'Verify Google account',
    'Verifikasi email': 'Verify email',
    'Daftar untuk mendapatkan akses ke layanan pariwisata Kabupaten Jember':
        'Register to access tourism services in Jember Regency.',
    'Nama lengkap hanya boleh berisi huruf dan spasi.':
        'Full name can only contain letters and spaces.',
    'Masukkan nomor telepon yang valid': 'Enter a valid phone number.',
    'Jenis tiket ketua tidak valid.': 'The leader ticket type is invalid.',
    'Data Ketua Kelompok': 'Group Leader Details',
    'E-ticket dan bukti transaksi akan dikirimkan ke kontak penanggung jawab ini.':
        'The e-ticket and payment receipt will be sent to this contact.',
    'Nama Lengkap (Ketua)': 'Full Name (Leader)',
    'Alamat Email': 'Email Address',
    'Peserta dan jenis tiket': 'Participants and Ticket Types',
    'Ketua dan setiap anggota memilih satu jenis tiket.':
        'The leader and each member must select one ticket type.',
    'Nama peserta hanya boleh berisi huruf dan spasi.':
        'Participant names can only contain letters and spaces.',
    'Pilih Pembayaran': 'Choose Payment',
    'Batas waktu pembayaran berakhir. Buat pemesanan baru untuk melanjutkan.':
        'The payment deadline has passed. Create a new booking to continue.',
    'Kode pembayaran belum tersedia. Hubungi pengelola atau coba lagi.': 'The payment code is unavailable. Contact the administrator or try again.',
    'Tautan pembayaran belum tersedia. Coba lagi.':
        'The payment link is unavailable. Try again.',
    'Halaman pembayaran tidak dapat dibuka.':
        'The payment page could not be opened.',
    'E-Tiket': 'E-Ticket',
    'Tanggal kunjungan': 'Visit Date',
    'Pindai kode pembayaran yang tampil di atas.':
        'Scan the payment code shown above.',
    'Selesaikan pembayaran dari aplikasi pembayaranmu.':
        'Complete the payment in your payment app.',
    'Status pesanan akan diperbarui otomatis.':
        'The order status will update automatically.',
    'Tekan Bayar Sekarang untuk membuka halaman pembayaran.':
        'Tap Pay Now to open the payment page.',
    'Pilih metode pembayaran yang tersedia.':
        'Choose an available payment method.',
    'Selesaikan pembayaran lalu kembali ke aplikasi untuk memeriksa status.':
        'Complete the payment, then return to the app to check its status.',
    'Coba Lagi': 'Try Again',
    'Bayar Sekarang': 'Pay Now',
    'Jenis tiket belum tersedia.': 'Ticket types are not available yet.',
    'Terima kasih! Ulasan Anda berhasil dikirim.':
        'Thank you! Your review has been submitted.',
    'Deskripsi destinasi belum tersedia.':
        'A destination description is not available yet.',
    'Jam operasional belum tersedia': 'Opening hours are not available yet.',
    'Lihat estimasi jarak & waktu': 'View distance and time estimate',
    'Perbarui estimasi rute': 'Update route estimate',
    'Jarak rute': 'Route Distance',
    'Estimasi berkendara': 'Estimated Driving Time',
    'Masuk untuk memesan': 'Sign in to book',
    'Pesan tiket': 'Book Tickets',
    'Belum tersedia': 'Not Available',
    'Terpopuler': 'Most Popular',
    'Rating Tertinggi': 'Highest Rated',
    'Jarak Terdekat': 'Nearest',
    'Harga Terendah': 'Lowest Price',
    'Lokasi tidak tersedia; jarak dihitung dari lokasi anda.': 'Location unavailable; distances are calculated from your default location.',
    'Lokasi gagal dimuat; jarak dihitung dari lokasi anda.': 'Could not load your location; distances are calculated from your default location.',
    'Pilihan wisata dengan jarak terdekat dari lokasi Anda':
        'Destinations closest to your location',
    'Pemesanan Tiket Wisata Lebih Praktis': 'Easier Tourist Ticket Booking',
    'Mode Tamu': 'Guest Mode',
    'Pesan tiket destinasi wisata di Kabupaten Jember secara online dengan mudah dan nyaman, kapan saja.': 'Book Jember Regency destination tickets online, easily and conveniently, anytime.',
    'Pembayaran QRIS yang Mudah dan Transparan':
        'Easy and Transparent QRIS Payments',
    'Selesaikan pembayaran dengan QRIS serta pantau status transaksi Anda secara praktis.':
        'Pay with QRIS and conveniently track your transaction status.',
    'E-Ticket Digital yang Siap Digunakan': 'Ready-to-Use Digital E-Ticket',
    'Dapatkan tiket digital dengan kode QR untuk memudahkan proses verifikasi saat tiba di destinasi wisata.': 'Get a digital ticket with a QR code for easy verification when you arrive at a destination.',
    'Riwayat Pemesanan Tersimpan Rapi': 'Your Booking History, Organized',
    'Akses kembali riwayat transaksi, detail pemesanan, dan informasi tiket Anda dalam satu akun.': 'Access your transaction history, booking details, and ticket information in one account.',
    'Pengelolaan Rombongan dan Jadwal yang Mudah':
        'Easy Group and Schedule Management',
    'Atur data ketua kelompok, anggota rombongan, serta jadwal kunjungan agar perjalanan lebih terencana.': 'Manage your group leader, members, and visit schedule to plan your trip.',
    'Pilih tanggal baru atau tambahkan minimal satu anggota.':
        'Select a new date or add at least one member.',
    'Lengkapi nama dan jenis tiket setiap anggota.':
        'Enter each member’s name and ticket type.',
    'Perubahan perjalanan belum dapat dikonfirmasi.':
        'Trip changes cannot be confirmed yet.',
    'Data perjalanan tidak tersedia.': 'Trip details are unavailable.',
    'Ubah jadwal': 'Change Schedule',
    'Pilih tanggal baru untuk kunjungan Anda.': 'Choose a new visit date.',
    'Tambah tiket': 'Add Tickets',
    'Tambahkan anggota atau tiket tambahan untuk perjalanan Anda.':
        'Add members or extra tickets to your trip.',
    'Selesaikan perubahan yang tertunda sebelum membuat perubahan baru.':
        'Complete pending changes before making new changes.',
    'Perubahan tertunda': 'Pending Changes',
    'Lihat perubahan': 'Review Changes',
    'Pilih tanggal atau tambah anggota': 'Choose a date or add members',
    'Lanjutkan pembayaran dari kartu perubahan di atas.':
        'Continue payment from the change card above.',
    'Periksa kembali perubahan sebelum melanjutkan.':
        'Review your changes before continuing.',
    'Jadwal tetap sampai Anda memilih perubahan.':
        'Your schedule stays the same until you choose to change it.',
    'Jumlah tiket': 'Number of Tickets',
    'Tiket tambahan': 'Additional Tickets',
    'Subtotal tambahan': 'Additional Subtotal',
    'Tiket aktif': 'Active Tickets',
    'Riwayat tiket': 'Ticket History',
    'Semua pesanan': 'All Bookings',
    'Tanggal Kunjungan': 'Visit Date',
    'Login terlebih dahulu': 'Please Sign In First',
    'login untuk memulai perjalananmu.': 'Sign in to start your journey.',
    'Yuk pesan tiket untuk memulai perjalananmu.':
        'Book a ticket to start your journey.',
    'Login sekarang': 'Sign In Now',
    'pesan tiket sekarang': 'Book Tickets Now',
    'Tidak diketahui': 'Unknown',
    'Terkonfirmasi': 'Confirmed',
    'Lokasi perangkat tidak tersedia. Aktifkan GPS dan izinkan akses lokasi.': 'Device location is unavailable. Turn on GPS and allow location access.',
    'Tidak ada destinasi dengan koordinat yang sesuai.':
        'No destinations with valid coordinates were found.',
    'Peta destinasi tidak dapat dimuat.':
        'The destination map could not be loaded.',
    'Lihat estimasi': 'View Estimate',
    'Perbarui estimasi': 'Update Estimate',
    'Server terlalu lama merespons. Periksa koneksi lalu coba lagi.': 'The server took too long to respond. Check your connection and try again.',
    'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi jaringan.': 'Could not connect to the server. Check the API address and your network connection.',
    'Server mengirim respons yang tidak dapat dibaca.':
        'The server returned an unreadable response.',
    'Format respons server tidak sesuai.':
        'The server returned an invalid response format.',
    'Server mengirim respons unduhan yang tidak valid.':
        'The server returned an invalid download response.',
    'Server tidak mengirim file PDF.': 'The server did not return a PDF file.',
    'Permintaan gagal. Silakan coba lagi.':
        'The request failed. Please try again.',
    'Periksa kembali data yang Anda masukkan.':
        'Please check the information you entered.',
    'Pendaftaran belum berhasil': 'Registration was unsuccessful',
    'Mengerti': 'Got it',
    'Nama lengkap wajib diisi.': 'Full name is required.',
    'Email wajib diisi.': 'Email is required.',
    'Nomor telepon wajib diisi.': 'Phone number is required.',
    'Kata sandi wajib diisi.': 'Password is required.',
    'Kode OTP wajib diisi.': 'OTP code is required.',
    'Alamat email tersebut sudah terdaftar.':
        'This email address is already registered.',
    'Nomor telepon tersebut sudah terdaftar.':
        'This phone number is already registered.',
    'Masukkan nomor telepon dengan format yang valid.':
        'Enter a valid phone number.',
    'Sembunyikan password': 'Hide Password',
    'Tampilkan password': 'Show Password',
    'Ulangi password': 'Repeat Password',
    'Sembunyikan konfirmasi password': 'Hide Password Confirmation',
    'Tampilkan konfirmasi password': 'Show Password Confirmation',
    'Daftar Akun JemberGo': 'Create a JemberGo Account',
    'Lanjutkan dengan Google': 'Continue with Google',
    'Sudah memiliki akun? ': 'Already have an account? ',
    'Belum memiliki akun? ': 'Don’t have an account? ',
    'Syarat & Ketentuan': 'Terms and Conditions',
    'Pilih tanggal': 'Select a Date',
    'Jumlah peserta': 'Number of Participants',
    'Total pesanan': 'Order Total',
    'Tunai di tempat': 'Cash on Site',
    'Lanjut bayar': 'Continue to Payment',
    'Konfirmasi': 'Confirm',
    'Lanjutkan pembayaran': 'Continue to Payment',
    'Masukkan nama lengkap': 'Enter your full name',
    'Alamat email': 'Email Address',
    'Masukkan email': 'Enter email',
    'Gunakan alamat email @gmail.com yang valid':
        'Use a valid @gmail.com email address',
  };

  static String translate(String value) {
    if (LanguagePreferenceService.locale.value.languageCode != 'en') {
      return value;
    }

    final exact = _english[value];
    if (exact != null) return exact;

    return switch (value) {
      final text when text.startsWith('Selamat datang, ') =>
        'Welcome, ${text.substring('Selamat datang, '.length)}',
      final text when text.startsWith('Dipublikasikan ') =>
        'Published ${text.substring('Dipublikasikan '.length)}',
      final text
          when text.startsWith('Masukkan kode 6 digit yang dikirim ke ') =>
        'Enter the 6-digit code sent to ${text.substring('Masukkan kode 6 digit yang dikirim ke '.length)}'
            .replaceFirst(
              '. Kode berlaku selama 10 menit.',
              '. The code is valid for 10 minutes.',
            ),
      final text when text.startsWith('Destinasi gagal dimuat: ') =>
        'Could not load destinations: ${text.substring('Destinasi gagal dimuat: '.length)}',
      final text when text.startsWith('Artikel gagal dimuat: ') =>
        'Could not load articles: ${text.substring('Artikel gagal dimuat: '.length)}',
      final text when text.startsWith('Detail terbaru tidak dapat dimuat: ') =>
        'Could not load the latest details: ${text.substring('Detail terbaru tidak dapat dimuat: '.length)}',
      final text when text.startsWith('PDF e-tiket gagal disimpan: ') =>
        'Could not save e-ticket PDF: ${text.substring('PDF e-tiket gagal disimpan: '.length)}',
      final text when text.startsWith('Destinasi terbaru gagal dimuat: ') =>
        'Could not load the latest destinations: ${translate(text.substring('Destinasi terbaru gagal dimuat: '.length))}',
      final text when text.startsWith('Profil gagal disegarkan: ') =>
        'Could not refresh profile: ${translate(text.substring('Profil gagal disegarkan: '.length))}',
      final text when text.startsWith('Profil gagal disimpan: ') =>
        'Could not save profile: ${translate(text.substring('Profil gagal disimpan: '.length))}',
      final text when text.startsWith('Respons profil tidak valid: ') =>
        'Invalid profile response: ${translate(text.substring('Respons profil tidak valid: '.length))}',
      final text when text.startsWith('Gagal menyimpan bahasa: ') =>
        'Could not save language preference: ${translate(text.substring('Gagal menyimpan bahasa: '.length))}',
      final text when text.startsWith('Status pembayaran: ') =>
        'Payment status: ${text.substring('Status pembayaran: '.length)}',
      final text when text.startsWith('Sisa tiket pada tanggal ini: ') =>
        'Tickets remaining for this date: ${text.substring('Sisa tiket pada tanggal ini: '.length).replaceFirst(' peserta.', ' people.')}',
      final text when text.startsWith('Buka ') =>
        'Open ${text.substring('Buka '.length)}',
      final text when text.contains(' jam ') && text.endsWith(' menit') =>
        text
            .replaceFirst(' jam ', ' hours ')
            .replaceFirst(' menit', ' minutes'),
      final text when text.endsWith(' tiket') =>
        '${text.substring(0, text.length - ' tiket'.length)} tickets',
      final text when text.endsWith(' jam') =>
        '${text.substring(0, text.length - ' jam'.length)} hours',
      final text when text.contains(' tiket · ') => text.replaceFirst(
        ' tiket · ',
        ' tickets · ',
      ),
      final text when text.startsWith('Ulas ') =>
        'Review ${text.substring('Ulas '.length)}',
      final text when text.startsWith('Hapus peserta ') =>
        'Remove participant ${text.substring('Hapus peserta '.length)}',
      final text
          when text.startsWith('Hapus ') && text.endsWith(' dari favorit') =>
        'Remove ${text.substring('Hapus '.length, text.length - ' dari favorit'.length)} from favorites',
      final text
          when text.startsWith('Tambahkan ') && text.endsWith(' ke favorit') =>
        'Add ${text.substring('Tambahkan '.length, text.length - ' ke favorit'.length)} to favorites',
      'Simpan favorit' => 'Save to Favorites',
      'Hapus favorit' => 'Remove from Favorites',
      final text when text.endsWith(' bintang') =>
        '${text.substring(0, text.length - ' bintang'.length)} stars',
      final text when text.startsWith('Anggota ') =>
        'Member ${text.substring('Anggota '.length)}',
      final text when text.startsWith('Tiket ') =>
        'Ticket ${text.substring('Tiket '.length)}',
      final text when text.contains(' tiket\nTanggal: ') => text.replaceFirst(
        ' tiket\nTanggal: ',
        ' tickets\nDate: ',
      ),
      final text when text.startsWith('Rp ') =>
        'IDR ${text.substring('Rp '.length)}',
      final text when text.startsWith('Anggota tambahan:') => text.replaceFirst(
        'Anggota tambahan:',
        'Additional members:',
      ),
      final text when text.startsWith('Biaya tambahan: ') =>
        'Additional cost: ${text.substring('Biaya tambahan: '.length)}',
      final text when text.startsWith('Tanggal kunjungan: ') =>
        'Visit date: ${text.substring('Tanggal kunjungan: '.length)}',
      final text when text.startsWith('Destinasi: ') =>
        'Destination: ${text.substring('Destinasi: '.length)}',
      final text when text.startsWith('Kode ') =>
        'Code ${text.substring('Kode '.length)}',
      final text when text.endsWith(' orang') =>
        '${text.substring(0, text.length - ' orang'.length)} people',
      final text when text.endsWith(' foto') =>
        '${text.substring(0, text.length - ' foto'.length)} photos',
      final text when text.endsWith(' ulasan') =>
        '${text.substring(0, text.length - ' ulasan'.length)} reviews',
      final text when text.endsWith(' ulasan)') =>
        '${text.substring(0, text.length - ' ulasan)'.length)} reviews)',
      final text when text.endsWith(' ulasan)') =>
        '${text.substring(0, text.length - ' ulasan)'.length)} reviews)',
      final text when text.endsWith(' destinasi') =>
        '${text.substring(0, text.length - ' destinasi'.length)} destinations',
      final text when text.endsWith(' peserta') =>
        '${text.substring(0, text.length - ' peserta'.length)} participants',
      final text when text.endsWith(' menit') =>
        '${text.substring(0, text.length - ' menit'.length)} minutes',
      final text
          when text.endsWith(
            ' slot tiket tersedia · maksimal 10 orang per pemesanan.',
          ) =>
        '${text.substring(0, text.length - ' slot tiket tersedia · maksimal 10 orang per pemesanan.'.length)} ticket slots available · up to 10 people per booking.',
      _ => value,
    };
  }

  static InlineSpan translateSpan(InlineSpan span) {
    if (span is TextSpan) {
      return TextSpan(
        text: span.text == null ? null : translate(span.text!),
        children: span.children?.map(translateSpan).toList(),
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        semanticsIdentifier: span.semanticsIdentifier,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }
    return span;
  }
}
