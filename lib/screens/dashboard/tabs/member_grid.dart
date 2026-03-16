import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/colors.dart';
import 'member_detail.dart';

class MemberGrid extends StatefulWidget {
  final List<QueryDocumentSnapshot> members;
  const MemberGrid({super.key, required this.members});

  @override
  State<MemberGrid> createState() => _MemberGridState();
}

class _MemberGridState extends State<MemberGrid> {
  String _search      = '';
  String _filterRole  = 'Semua';
  String _filterSort  = 'Terbaru';

  final List<String> _roles = [
    'Semua', 'Owner', 'Admin', 'Member Senior', 'Member'
  ];
  final List<String> _sorts = ['Terbaru', 'Terlama'];

  List<QueryDocumentSnapshot> get _filtered {
    List<QueryDocumentSnapshot> list = widget.members;

    if (_filterRole != 'Semua') {
      list = list.where((m) {
        final data = m.data() as Map<String, dynamic>;
        return (data['role'] ?? 'Member') == _filterRole;
      }).toList();
    }

    if (_search.isNotEmpty) {
      list = list.where((m) {
        final data = m.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(_search.toLowerCase());
      }).toList();
    }

    list.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['createdAt'];
      final bTime = bData['createdAt'];
      if (aTime == null || bTime == null) return 0;
      final aDate = (aTime as dynamic).toDate();
      final bDate = (bTime as dynamic).toDate();
      return _filterSort == 'Terbaru'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (val) => setState(() => _search = val),
          decoration: InputDecoration(
            hintText: 'Cari anggota...',
            hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: AppColors.textDim, size: 20),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ..._sorts.map((sort) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterSort = sort),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filterSort == sort
                        ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterSort == sort
                          ? AppColors.primary : AppColors.border)),
                  child: Text(sort, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: _filterSort == sort
                        ? Colors.white : AppColors.textDim)),
                ),
              ),
            )),

            Container(width: 1, height: 20,
              color: AppColors.border,
              margin: const EdgeInsets.only(right: 8)),

            ..._roles.map((role) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterRole = role),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filterRole == role
                        ? _getRoleColor(role) : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterRole == role
                          ? _getRoleColor(role) : AppColors.border)),
                  child: Text(role, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: _filterRole == role
                        ? Colors.white : AppColors.textDim)),
                ),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Jumlah hasil
        Text('${filtered.length} anggota',
          style: TextStyle(fontSize: 11, color: AppColors.textDim,
            fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Grid
        filtered.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Tidak ada anggota ditemukan.',
                    style: TextStyle(color: AppColors.textDim)),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final docId = filtered[index].id; // ← doc ID = uid
                  final m     = filtered[index].data() as Map<String, dynamic>;
                  final photo = m['photoBase64'] ?? '';
                  final name  = m['name']        ?? 'Anggota';
                  final role  = m['role']        ?? 'Member';
                  final asal  = m['asal']        ?? '';

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemberDetail(
                          // Pastikan uid ikut terkirim ke MemberDetail
                          memberData: {...m, 'uid': docId},
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFD946EF)
                                ]),
                              borderRadius: BorderRadius.circular(22)),
                            padding: const EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: photo.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(photo),
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.purple.shade100,
                                      child: const Icon(Icons.person,
                                        color: Colors.purple, size: 32)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nama
                          Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMain)),
                          const SizedBox(height: 4),

                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20)),
                            child: Text(role.toUpperCase(),
                              style: TextStyle(fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: _getRoleColor(role))),
                          ),

                          if (asal.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_outlined,
                                  size: 10, color: AppColors.textDim),
                                const SizedBox(width: 2),
                                Flexible(child: Text(asal,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10,
                                    color: AppColors.textDim))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Owner':         return Colors.orange.shade600;
      case 'Admin':         return Colors.purple.shade600;
      case 'Member Senior': return Colors.blue.shade600;
      default:              return Colors.grey.shade600;
    }
  }
}