import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../../../core/mock_data.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  String subView = 'main'; 
  final TextEditingController _msgController = TextEditingController();

  // Method dipanggil dari DashboardScreen untuk mereset view
  void resetToMain() {
    if (subView != 'main') {
      setState(() => subView = 'main');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subView == 'forum') return _buildForumView();
    if (subView == 'rules' || subView == 'members') return _buildSimpleListView(subView);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SELAMAT DATANG,', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
                Text(MockData.userData['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF818CF8)])),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(MockData.userData['pic']!, fit: BoxFit.cover)),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFC026D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Marga', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              SizedBox(height: 4),
              Text('Cek kanal Discord untuk agenda mabar minggu ini.', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text('MENU UTAMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMenuCard(Icons.menu_book, 'Panduan', () => setState(() => subView = 'rules')),
            const SizedBox(width: 16),
            _buildMenuCard(Icons.people, 'Anggota', () => setState(() => subView = 'members')),
            const SizedBox(width: 16),
            _buildMenuCard(Icons.chat_bubble_outline, 'Diskusi', () => setState(() => subView = 'forum')),
          ],
        ),
        const SizedBox(height: 32),

        const Text('AKTIVITAS TERKINI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDim)),
        const SizedBox(height: 16),
        _buildActivityCard('Shadow_Master memposting', '"Persiapan Event Mabar Nasional..."', '10 menit yang lalu'),
        const SizedBox(height: 12),
        _buildActivityCard('Dokumen Diperbarui', 'SOP Komunitas V2.1 telah dirilis.', '2 jam yang lalu'),
      ],
    );
  }

  Expanded _buildMenuCard(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 28),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 6), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                const SizedBox(height: 8),
                Text(time.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textDim)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildForumView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: GestureDetector(
            onTap: () => setState(() => subView = 'main'),
            child: const Row(
              children: [
                Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
                Text('KEMBALI', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Align(alignment: Alignment.centerLeft, child: Text('Diskusi.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary))),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: MockData.messages.length,
            itemBuilder: (context, index) {
              final msg = MockData.messages[index];
              final isMe = msg['user'] == MockData.userData['name'];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(msg['user'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDim)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary : AppColors.card,
                        border: isMe ? null : Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 0), bottomRight: Radius.circular(isMe ? 0 : 16)),
                      ),
                      child: Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : AppColors.textMain, fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textDim),
                    filled: true, fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_msgController.text.isNotEmpty) {
                    setState(() {
                      MockData.messages.add({'id': DateTime.now().millisecondsSinceEpoch, 'user': MockData.userData['name'], 'text': _msgController.text, 'time': 'Baru saja'});
                      _msgController.clear();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSimpleListView(String viewType) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
      children: [
        GestureDetector(
          onTap: () => setState(() => subView = 'main'),
          child: const Row(
            children: [
              Icon(Icons.chevron_left, color: AppColors.accent, size: 20),
              Text('KEMBALI', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(viewType == 'rules' ? 'Panduan.' : 'Anggota.', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.primary)),
        const SizedBox(height: 24),
        if (viewType == 'rules') ...[
          _buildListTile('SOP Komunitas'),
          const SizedBox(height: 12),
          _buildListTile('Kode Etik'),
        ] else ...[
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: 9,
            itemBuilder: (context, index) => Container(color: Colors.grey.shade300, child: Image.network('https://picsum.photos/400?sig=${index + 50}', fit: BoxFit.cover)),
          )
        ]
      ],
    );
  }

  Widget _buildListTile(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textDim),
        ],
      ),
    );
  }
}