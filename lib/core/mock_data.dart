class MockData {
  static final Map<String, dynamic> userData = {
    'name': 'Anggota Void',
    'displayName': 'V-99201',
    'bio': 'Kesunyian adalah kekuatan. Marga Void selamanya.',
    'pic': 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?w=400&q=80',
    'role': 'Member Senior',
  };

  // Dibuat tidak 'final' sepenuhnya agar bisa ditambah (simulasi state pesan baru)
  static List<Map<String, dynamic>> messages = [
    {'id': 1, 'user': 'Aris_Void', 'text': 'Halo semua, kapan mabar lagi?', 'time': '12:40'},
    {'id': 2, 'user': 'Shadow_Master', 'text': 'Mungkin malam minggu ini di Discord.', 'time': '12:42'},
  ];

  static final List<Map<String, dynamic>> events = [
    {'id': 1, 'title': 'Townhall Marga Void Q1', 'date': '28 Feb 2026', 'time': '19:00 WIB', 'type': 'Online Meeting'},
    {'id': 2, 'title': 'Workshop Pengembangan Web', 'date': '05 Mar 2026', 'time': '15:00 WIB', 'type': 'Webinar'}
  ];
}