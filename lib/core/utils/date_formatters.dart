const _indonesianWeekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _indonesianMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String formatIndonesianDate(DateTime date) =>
    '${_indonesianWeekdays[date.weekday - 1]}, '
    '${date.day} ${_indonesianMonths[date.month - 1]} ${date.year}';
