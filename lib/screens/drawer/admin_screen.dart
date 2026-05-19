import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);
const Color cardBlue = Color(0xFF1E5C78);

// ─────────────────────────────────────────────
// ENTRY POINT — guards admin access
// ─────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _checkIsAdmin();
  }

  Future<bool> _checkIsAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data()?['isAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<bool>(
        future: _isAdminFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentOrange));
          }
          if (snap.hasError || !(snap.data ?? false)) {
            return _AccessDenied(tp: tp);
          }
          return AdminConsole(tp: tp);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACCESS DENIED
// ─────────────────────────────────────────────
class _AccessDenied extends StatelessWidget {
  final ThemeProvider tp;
  const _AccessDenied({required this.tp});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gpp_maybe_rounded, size: 80, color: accentOrange),
          const SizedBox(height: 20),
          Text('Access Restricted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tp.textColor)),
          const SizedBox(height: 8),
          Text('Admin credentials required.', style: TextStyle(color: tp.subTextColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN CONSOLE — tabbed layout
// ─────────────────────────────────────────────
class AdminConsole extends StatefulWidget {
  final ThemeProvider tp;
  const AdminConsole({super.key, required this.tp});

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _userCount = 0;

  final List<_TabItem> _tabs = const [
    _TabItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _TabItem(icon: Icons.group_rounded, label: 'Users'),
    _TabItem(icon: Icons.campaign_rounded, label: 'Broadcast'),
    _TabItem(icon: Icons.forum_rounded, label: 'Feedback'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _userCount = snapshot.docs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.tp;
    return Column(
      children: [
        // ── HEADER ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: accentOrange, size: 16),
                  SizedBox(width: 8),
                  Text('ADMIN COMMAND',
                      style: TextStyle(
                          color: accentOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 10)),
                ],
              ),
              const SizedBox(height: 6),
              Text('System Console',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)),
              const SizedBox(height: 20),

              // ── TAB BAR ──────────────────────
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final selected = _tabController.index == i;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _tabController.animateTo(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? primaryDark : tp.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: selected
                              ? [BoxShadow(color: primaryDark.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(_tabs[i].icon,
                                size: 16,
                                color: selected ? accentOrange : tp.subTextColor),
                            const SizedBox(width: 7),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Text(
                                  _tabs[i].label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : tp.subTextColor,
                                  ),
                                ),

                                if (i == 1 && _userCount > 0)
                                  Positioned(
                                    top: -6,
                                    right: -14,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: accentOrange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$_userCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── TAB CONTENT ─────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _OverviewTab(tp: tp),
              _UsersTab(tp: tp),
              _BroadcastTab(tp: tp),
              _FeedbackTab(tp: tp),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ═══════════════════════════════════════════════
// ═══════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ═══════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final ThemeProvider tp;

  const _OverviewTab({required this.tp});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feedback')
              .snapshots(),
          builder: (context, fbSnap) {

            // Loading
            if (userSnap.connectionState == ConnectionState.waiting ||
                fbSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentOrange,
                ),
              );
            }

            // Error
            if (userSnap.hasError || fbSnap.hasError) {
              return Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(color: tp.textColor),
                ),
              );
            }

            // Users
            final userDocs = userSnap.data?.docs ?? [];

            // Feedback
            final feedbackDocs = fbSnap.data?.docs ?? [];

            // Stats
            final userCount = userDocs.length;

            final fbCount = feedbackDocs.length;

            final adminCount = userDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isAdmin'] == true;
            }).length;

            // Average rating
            double avgRating = 0;

            final ratings = feedbackDocs
                .map((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['rating'] ?? 0) as num;
            })
                .where((r) => r > 0)
                .toList();

            if (ratings.isNotEmpty) {
              avgRating =
                  ratings.reduce((a, b) => a + b) / ratings.length;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
              physics: const BouncingScrollPhysics(),
              children: [

                // ─────────────────────────────
                // STATS GRID
                // ─────────────────────────────

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.35,
                  children: [

                    _StatCard(
                      tp: tp,
                      icon: Icons.people_rounded,
                      label: 'Total Users',
                      value: userCount.toString(),
                      color: primaryDark,
                    ),

                    _StatCard(
                      tp: tp,
                      icon: Icons.forum_rounded,
                      label: 'Feedback',
                      value: fbCount.toString(),
                      color: accentOrange,
                    ),

                    _StatCard(
                      tp: tp,
                      icon: Icons.star_rounded,
                      label: 'Avg Rating',
                      value: avgRating > 0
                          ? avgRating.toStringAsFixed(1)
                          : '—',
                      color: cardBlue,
                    ),

                    _StatCard(
                      tp: tp,
                      icon: Icons.shield_rounded,
                      label: 'Admins',
                      value: adminCount.toString(),
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ─────────────────────────────
                // RECENT USERS
                // ─────────────────────────────

                _sectionLabel(tp, 'Recent Signups'),

                const SizedBox(height: 15),

                if (userDocs.isEmpty)
                  Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: tp.subTextColor),
                    ),
                  )
                else
                  ...userDocs.take(5).map((doc) {

                    final data =
                    doc.data() as Map<String, dynamic>;

                    final ts = data['createdAt'] as Timestamp?;

                    return _MiniUserRow(
                      tp: tp,
                      name: data['username'] ?? 'Unknown',
                      email: data['email'] ?? '',
                      isAdmin: data['isAdmin'] == true,
                      date: ts != null
                          ? DateFormat('MMM d, yyyy')
                          .format(ts.toDate())
                          : '—',
                    );
                  }),

                const SizedBox(height: 30),

                // ─────────────────────────────
                // SYSTEM HEALTH
                // ─────────────────────────────

                _sectionLabel(tp, 'System Health'),

                const SizedBox(height: 15),

                _SystemHealthCard(tp: tp),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 2 — USER MANAGEMENT
// ═══════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final ThemeProvider tp;
  const _UsersTab({required this.tp});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.tp;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: tp.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.2 : 0.04), blurRadius: 10)],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(color: tp.textColor),
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                hintStyle: TextStyle(color: tp.subTextColor.withValues(alpha: 0.5), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: tp.isDarkMode ? accentOrange : primaryDark),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: tp.subTextColor),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: accentOrange,
                  ),
                );
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No data found',
                    style: TextStyle(color: tp.subTextColor),
                  ),
                );
              }

              var docs = snap.data!.docs;
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['username'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                      (data['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(child: Text('No users found.', style: TextStyle(color: tp.subTextColor)));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _UserTile(tp: tp, doc: docs[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatefulWidget {
  final ThemeProvider tp;
  final DocumentSnapshot doc;
  const _UserTile({required this.tp, required this.doc});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _toggling = false;

  Future<void> _toggleAdmin(bool currentValue) async {
    setState(() => _toggling = true);
    HapticFeedback.mediumImpact();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doc.id)
          .update({'isAdmin': !currentValue});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: accentOrange),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _showDeleteUserDialog(BuildContext context, String userId, String name) {
    final tp = widget.tp;
    // Prevent admin from deleting themselves
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't delete your own account here."), backgroundColor: accentOrange),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        tp: tp,
        icon: Icons.person_remove_rounded,
        title: 'Remove User?',
        message: 'This will permanently delete $name\'s account data from Firestore.',
        confirmLabel: 'REMOVE',
        onConfirm: () async {
          await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        },
      ),
    );
  }

  void _showUserTransactions(
      BuildContext context,
      String uid,
      String name,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserTransactionsSheet(
        uid: uid,
        name: name,
        tp: widget.tp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.tp;
    final data = widget.doc.data() as Map<String, dynamic>;
    final isAdmin = data['isAdmin'] == true;
    final ts = data['createdAt'] as Timestamp?;
    final isSelf = widget.doc.id == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: isSelf ? Border.all(color: accentOrange.withValues(alpha: 0.4), width: 1.5) : null,
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: accentOrange,
        collapsedIconColor: tp.subTextColor,
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isAdmin ? accentOrange : Colors.transparent, width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: tp.isDarkMode ? Colors.white10 : primaryDark.withValues(alpha: 0.08),
            child: Text(
              (data['username'] ?? '?')[0].toUpperCase(),
              style: TextStyle(color: tp.isDarkMode ? accentOrange : primaryDark, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                data['username'] ?? 'Unknown',
                style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('YOU', style: TextStyle(fontSize: 9, color: accentOrange, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          data['email'] ?? '—',
          style: TextStyle(fontSize: 12, color: tp.subTextColor),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isAdmin
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Text('ADMIN', style: TextStyle(fontSize: 10, color: accentOrange, fontWeight: FontWeight.bold)),
        )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          // Details grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tp.isDarkMode ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FEFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _detailRow(tp, 'Bank', data['bank_name'] ?? '—'),
                const SizedBox(height: 8),
                _detailRow(tp, 'Account', data['account_number'] ?? '—'),
                const SizedBox(height: 8),
                _detailRow(tp, 'Phone', data['phone_number'] ?? '—'),
                const SizedBox(height: 8),
                _detailRow(tp, 'Joined', ts != null ? DateFormat('MMM d, yyyy').format(ts.toDate()) : '—'),
              ],
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showUserTransactions(
                context,
                widget.doc.id,
                data['username'] ?? 'User',
              ),
              icon: const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: accentOrange,
              ),
              label: const Text(
                'VIEW TRANSACTIONS',
                style: TextStyle(
                  color: accentOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Admin toggle
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: isAdmin
                          ? [Colors.red.shade800, Colors.red.shade600]
                          : [primaryDark, cardBlue],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isSelf || _toggling ? null : () => _toggleAdmin(isAdmin),
                    icon: _toggling
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(isAdmin ? Icons.shield_rounded : Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
                    label: Text(
                      isAdmin ? 'REVOKE ADMIN' : 'GRANT ADMIN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Delete button
              Container(
                decoration: BoxDecoration(
                  color: tp.isDarkMode ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
                  onPressed: isSelf ? null : () => _showDeleteUserDialog(context, widget.doc.id, data['username'] ?? 'User'),
                  tooltip: 'Remove user',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(ThemeProvider tp, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: tp.subTextColor, fontSize: 12)),
        Text(value, style: TextStyle(color: tp.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _UserTransactionsSheet extends StatelessWidget {
  final String uid;
  final String name;
  final ThemeProvider tp;

  const _UserTransactionsSheet({
    required this.uid,
    required this.name,
    required this.tp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name Transactions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tp.textColor,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snap.hasData ||
                    snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        color: tp.subTextColor,
                      ),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data =
                    docs[i].data() as Map<String, dynamic>;

                    return Card(
                      color: tp.isDarkMode
                          ? Colors.white10
                          : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          accentOrange.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.currency_rupee_rounded,
                            color: accentOrange,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Expense',
                          style: TextStyle(
                            color: tp.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['category'] ?? '',
                          style: TextStyle(
                            color: tp.subTextColor,
                          ),
                        ),
                        trailing: Text(
                          '₹${data['amount'] ?? 0}',
                          style: const TextStyle(
                            color: accentOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 3 — BROADCAST NOTIFICATIONS
// ═══════════════════════════════════════════════
class _BroadcastTab extends StatefulWidget {
  final ThemeProvider tp;
  const _BroadcastTab({required this.tp});

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': _msgCtrl.text.trim(),
        'url': _urlCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _msgCtrl.clear();
      _urlCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Broadcast sent to all users!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: accentOrange),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showEditBroadcastDialog(
      BuildContext context,
      String docId,
      String oldMessage,
      String oldUrl,
      ) {
    final tp = widget.tp;

    final messageController =
    TextEditingController(text: oldMessage);

    final urlController =
    TextEditingController(text: oldUrl);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tp.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        title: Text(
          'Edit Broadcast',
          style: TextStyle(
            color: tp.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: messageController,
                maxLines: 4,
                style: TextStyle(color: tp.textColor),

                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: urlController,
                style: TextStyle(color: tp.textColor),

                decoration: InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        actionsPadding:
        const EdgeInsets.fromLTRB(16, 0, 16, 16),

        actions: [

          // Cancel Button
          SizedBox(
            height: 46,
            child: TextButton(
              onPressed: () => Navigator.pop(context),

              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: tp.subTextColor.withValues(alpha: 0.2),
                  ),
                ),
                backgroundColor: tp.isDarkMode
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade100,
              ),

              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: tp.subTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Update Button
          Container(
            height: 46,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),

              gradient: const LinearGradient(
                colors: [primaryDark, cardBlue],
              ),

              boxShadow: [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: ElevatedButton.icon(
              onPressed: () async {

                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(docId)
                    .update({
                  'message':
                  messageController.text.trim(),

                  'url':
                  urlController.text.trim(),

                  'updatedAt':
                  FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Broadcast updated successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: primaryDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 18,
              ),

              label: const Text(
                'UPDATE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBroadcastDialog(BuildContext context, String docId) {
    final tp = widget.tp;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        tp: tp,
        icon: Icons.message_outlined,
        title: 'Remove Broadcast?',
        message: 'This will permanently delete this broadcast msg from Firestore.',
        confirmLabel: 'REMOVE',
        onConfirm: () async {
          await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.tp;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── COMPOSE CARD ────────────────────────
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: tp.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.15 : 0.04), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: accentOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.campaign_rounded, color: accentOrange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Compose Broadcast',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: tp.textColor)),
                  ],
                ),
                const SizedBox(height: 20),

                // Message field
                TextFormField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: TextStyle(color: tp.textColor, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Type your announcement here…',
                    hintStyle: TextStyle(color: tp.subTextColor.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: tp.isDarkMode ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FEFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: accentOrange, width: 1.5)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                ),
                const SizedBox(height: 15),

                // URL field (optional)
                TextFormField(
                  controller: _urlCtrl,
                  style: TextStyle(color: tp.textColor, fontWeight: FontWeight.w500),
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'Link URL (optional)',
                    hintStyle: TextStyle(color: tp.subTextColor.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.link_rounded, color: tp.isDarkMode ? accentOrange : primaryDark, size: 20),
                    filled: true,
                    fillColor: tp.isDarkMode ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FEFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: accentOrange, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Send button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [primaryDark, cardBlue]),
                    boxShadow: [BoxShadow(color: primaryDark.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendBroadcast,
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _isSending ? 'SENDING…' : 'BROADCAST TO ALL USERS',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
        _sectionLabel(tp, 'Sent Notifications'),
        const SizedBox(height: 15),

        // ── NOTIFICATION HISTORY ─────────────────
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: accentOrange,
                ),
              );
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No data found',
                  style: TextStyle(color: tp.subTextColor),
                ),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text('No broadcasts sent yet.', style: TextStyle(color: tp.subTextColor)));
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: tp.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.12 : 0.03), blurRadius: 8)],
                  ),
                  child: ListTile(
                    onTap: () => _showEditBroadcastDialog(
                      context,
                      doc.id,
                      data['message'] ?? '',
                      data['url'] ?? '',
                    ),

                    contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),

                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: accentOrange,
                        size: 18,
                      ),
                    ),

                    title: Text(
                      data['message'] ?? '',
                      style: TextStyle(
                        color: tp.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        if ((data['url'] ?? '').toString().isNotEmpty)
                          Text(
                            data['url'],
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),

                        Text(
                          ts != null
                              ? DateFormat('MMM d, h:mm a').format(ts.toDate())
                              : 'Just now',
                          style: TextStyle(
                            color: tp.subTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showDeleteBroadcastDialog(context, doc.id),
                      tooltip: 'Delete notification',
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// TAB 4 — FEEDBACK HUB (upgraded from original)
// ═══════════════════════════════════════════════
class _FeedbackTab extends StatelessWidget {
  final ThemeProvider tp;
  const _FeedbackTab({required this.tp});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: accentOrange,
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No data found',
              style: TextStyle(color: tp.subTextColor),
            ),
          );
        }
        final docs = snap.data!.docs;

        // Compute rating distribution
        final Map<int, int> ratingDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final d in docs) {
          final r = ((d.data() as Map)['rating'] ?? 0) as int;
          if (r >= 1 && r <= 5) ratingDist[r] = (ratingDist[r] ?? 0) + 1;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          physics: const BouncingScrollPhysics(),
          children: [
            // Rating distribution bar chart
            if (docs.isNotEmpty) ...[
              _sectionLabel(tp, 'Rating Distribution'),
              const SizedBox(height: 15),
              _RatingDistributionCard(tp: tp, distribution: ratingDist, total: docs.length),
              const SizedBox(height: 30),
            ],

            _sectionLabel(tp, 'User Feedback Log (${docs.length})'),
            const SizedBox(height: 15),

            if (docs.isEmpty)
              Center(child: Text('No feedback received yet.', style: TextStyle(color: tp.subTextColor)))
            else
              ...docs.map((doc) => _FeedbackTile(tp: tp, doc: doc)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SHARED HELPER WIDGETS
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final ThemeProvider tp;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.tp, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.15 : 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: tp.textColor)),
              Text(label,
                  style: TextStyle(color: tp.subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniUserRow extends StatelessWidget {
  final ThemeProvider tp;
  final String name, email, date;
  final bool isAdmin;
  const _MiniUserRow({required this.tp, required this.name, required this.email, required this.isAdmin, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.1 : 0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tp.isDarkMode ? Colors.white10 : primaryDark.withValues(alpha: 0.08),
            child: Text(name[0].toUpperCase(), style: TextStyle(color: tp.isDarkMode ? accentOrange : primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor, fontSize: 14)),
                Text(email, style: TextStyle(color: tp.subTextColor, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ADMIN', style: TextStyle(color: accentOrange, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              Text(date, style: TextStyle(color: tp.subTextColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  final ThemeProvider tp;
  const _SystemHealthCard({required this.tp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryDark, cardBlue]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primaryDark.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _healthRow('Firebase Auth', true),
          const SizedBox(height: 12),
          _healthRow('Firestore DB', true),
          const SizedBox(height: 12),
          _healthRow('FCM Messaging', true),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: checkApiHealth(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _healthRow('AI Prediction API', null);
              }

              return _healthRow(
                'AI Prediction API',
                snapshot.data == true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _healthRow(String label, bool? healthy) {
    return Row(
      children: [
        Icon(
          healthy == null ? Icons.help_outline_rounded : (healthy ? Icons.check_circle_rounded : Icons.error_outline_rounded),
          color: healthy == null ? Colors.white38 : (healthy ? Colors.green : Colors.redAccent),
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        Text(
          healthy == null ? 'UNKNOWN' : (healthy ? 'OPERATIONAL' : 'DOWN'),
          style: TextStyle(
            color: healthy == null ? Colors.white38 : (healthy ? Colors.orangeAccent : Colors.redAccent),
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('https://ec7e20d3-e5ba-40e2-845e-187b9f5b8daf-00-eorlqbv9c1kw.sisko.replit.dev/health'),);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class _RatingDistributionCard extends StatelessWidget {
  final ThemeProvider tp;
  final Map<int, int> distribution;
  final int total;
  const _RatingDistributionCard({required this.tp, required this.distribution, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.15 : 0.04), blurRadius: 12)],
      ),
      child: Column(
        children: List.generate(5, (i) {
          final star = 5 - i;
          final count = distribution[star] ?? 0;
          final fraction = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text('$star', style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded, size: 14, color: accentOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor: tp.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        star >= 4 ? accentOrange : (star == 3 ? Colors.orangeAccent : Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text('$count', style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final ThemeProvider tp;
  final DocumentSnapshot doc;
  const _FeedbackTile({required this.tp, required this.doc});

  void _showDeleteConfirm(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        tp: tp,
        icon: Icons.delete_sweep_rounded,
        title: 'Delete Feedback?',
        message: 'This will permanently erase this feedback.',
        confirmLabel: 'DELETE',
        onConfirm: () async {
          await FirebaseFirestore.instance.collection('feedback').doc(doc.id).delete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final rating = (data['rating'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: tp.isDarkMode ? 0.12 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: accentOrange,
        collapsedIconColor: tp.subTextColor,
        leading: CircleAvatar(
          backgroundColor: tp.isDarkMode ? Colors.white10 : primaryDark.withValues(alpha: 0.05),
          child: Text(
            (data['userName'] ?? '?')[0].toUpperCase(),
            style: TextStyle(color: tp.textColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(data['userName'] ?? 'Anonymous',
            style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
        subtitle: Text(
          timestamp != null ? DateFormat('MMM d • h:mm a').format(timestamp.toDate()) : 'Recent',
          style: TextStyle(fontSize: 11, color: tp.subTextColor),
        ),
        trailing: _RatingBadge(tp: tp, rating: rating),
        childrenPadding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: tp.isDarkMode ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FEFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              data['feedback'] ?? 'No text provided.',
              style: TextStyle(color: tp.textColor, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showDeleteConfirm(context),
              icon: const Icon(Icons.delete_outline_rounded, color: accentOrange, size: 18),
              label: const Text('PURGE', style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final ThemeProvider tp;
  final int rating;
  const _RatingBadge({required this.tp, required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Text('—', style: TextStyle(fontSize: 11, color: tp.subTextColor, fontWeight: FontWeight.bold)),
      );
    }
    final isGood = rating >= 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: isGood ? accentOrange: Colors.redAccent),
          const SizedBox(width: 4),
          Text('$rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isGood ? accentOrange : Colors.redAccent)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE CONFIRM DIALOG
// ─────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final ThemeProvider tp;
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final Future<void> Function() onConfirm;

  const _ConfirmDialog({
    required this.tp,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tp.cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: accentOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: accentOrange, size: 36),
            ),
            const SizedBox(height: 18),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: tp.textColor)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: tp.subTextColor, fontSize: 14, height: 1.5)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [primaryDark, cardBlue]),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(confirmLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED LABEL HELPER
// ─────────────────────────────────────────────
Widget _sectionLabel(ThemeProvider tp, String title) {
  return Text(
    title.toUpperCase(),
    style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
  );
}