import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/database/service.dart';

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({Key? key}) : super(key: key);

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isAdmin = false;
  bool isChecking = true;

  // Key untuk refresh StreamBuilder secara manual
  final GlobalKey _pelangganKey = GlobalKey();
  final GlobalKey _penggunaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        isAdmin = authProvider.currentUser?.jabatan == 'admin';
        isChecking = false;
      });
    }
  }

  // Fungsi refresh manual
  void _refreshCurrentTab() {
    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      // Refresh tab Pelanggan
      _pelangganKey.currentState?.setState(() {});
    } else {
      // Refresh tab Pengguna
      _penggunaKey.currentState?.setState(() {});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data diperbarui!'), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 235, 25, 10),
        elevation: 0,
        leading: Container(),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh Data',
                  onPressed: _refreshCurrentTab,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (isAdmin)
            Container(
              color: const Color.fromARGB(255, 235, 25, 10),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Pelanggan'),
                  Tab(text: 'Pengguna'),
                ],
              ),
            ),
          Expanded(
            child: isChecking
                ? const Center(child: CircularProgressIndicator())
                : _buildContentBasedOnRole(),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: const Color.fromARGB(255, 235, 25, 10),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
    );
  }

  Widget _buildContentBasedOnRole() {
    if (!isAdmin) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Akses Ditolak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Hanya admin yang dapat mengakses halaman ini',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPelangganStream(),
        _buildPenggunaStream(),
      ],
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      _showAddPelangganDialog();
    } else {
      _showAddUserDialog();
    }
  }

  // ==================== PELANGGAN (REAL-TIME + RELOAD) ====================
  Widget _buildPelangganStream() {
    final stream = Provider.of<AuthProvider>(context, listen: false)
        .customerService
        .getAllCustomersStream();

    return StreamBuilder<List<Map<String, dynamic>>>(
      key: _pelangganKey, // <-- KEY UNTUK REFRESH
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _refreshCurrentTab,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada pelanggan'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: data.length,
          itemBuilder: (context, index) => _buildCustomerCard(data[index]),
        );
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_outline,
              color: const Color.fromARGB(255, 235, 25, 10),
            )),
        title: Text(customer['nama'] ?? 'Tanpa Nama',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(customer['no_telepon'] ?? '-',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _showDeletePelangganDialog(customer['id']),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () => _showEditPelangganDialog(customer),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PENGGUNA (REAL-TIME + RELOAD) ====================
  Widget _buildPenggunaStream() {
    final stream = Provider.of<AuthProvider>(context, listen: false)
        .userService
        .getAllUsersStream();

    return StreamBuilder<List<Map<String, dynamic>>>(
      key: _penggunaKey, // <-- KEY UNTUK REFRESH
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: const Color.fromARGB(255, 235, 25, 10),
                ),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _refreshCurrentTab,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada pengguna'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: data.length,
          itemBuilder: (context, index) => _buildUserCard(data[index]),
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_outline,
              color: const Color.fromARGB(255, 235, 25, 10),
            )),
        title: Text(user['nama'] ?? 'Tanpa Nama',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text('${user['jabatan'] ?? '-'} • ${user['email'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: const Color.fromARGB(255, 235, 25, 10),
              ),
              onPressed: () => _showDeleteUserDialog(user['id']),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () => _showEditUserDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CRUD DIALOGS (TETAP SAMA) ====================
  // ... (semua fungsi dialog tetap sama seperti sebelumnya)
  // Karena terlalu panjang, saya biarkan tetap seperti kode kamu sebelumnya
  // Tidak ada perubahan di bagian dialog

  void _showAddPelangganDialog() {
    final namaC = TextEditingController();
    final telpC = TextEditingController();
    final alamatC = TextEditingController();
    final emailC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: namaC,
                decoration: const InputDecoration(
                    labelText: 'Nama *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: telpC,
                decoration: const InputDecoration(
                    labelText: 'No. Telepon *', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(
                controller: alamatC,
                decoration: const InputDecoration(
                    labelText: 'Alamat', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: emailC,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: const TextStyle(
                  color: Color.fromARGB(230, 17, 0, 0),
                ),
              )),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 235, 25, 10),
            ),
            onPressed: () async {
              if (namaC.text.trim().isEmpty || telpC.text.trim().isEmpty)
                return;
              final result =
                  await Provider.of<AuthProvider>(context, listen: false)
                      .customerService
                      .createCustomer(
                        nama: namaC.text.trim(),
                        noTelepon: telpC.text.trim(),
                        alamat: alamatC.text.trim().isEmpty
                            ? null
                            : alamatC.text.trim(),
                        email: emailC.text.trim().isEmpty
                            ? null
                            : emailC.text.trim(),
                      );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message'] ?? 'Sukses'),
                backgroundColor: result['success']
                    ? Colors.green
                    : const Color.fromARGB(255, 235, 25, 10),
              ));
            },
            child: const Text(
              'Simpan',
              style: const TextStyle(
                color: Color.fromARGB(230, 17, 0, 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPelangganDialog(Map<String, dynamic> customer) {
    final namaC = TextEditingController(text: customer['nama']);
    final telpC = TextEditingController(text: customer['no_telepon']);
    final alamatC = TextEditingController(text: customer['alamat'] ?? '');
    final emailC = TextEditingController(text: customer['email'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: namaC,
                decoration: const InputDecoration(
                    labelText: 'Nama *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: telpC,
                decoration: const InputDecoration(
                    labelText: 'No. Telepon *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: alamatC,
                decoration: const InputDecoration(
                    labelText: 'Alamat', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: emailC,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: const TextStyle(
                  color: Color.fromARGB(230, 17, 0, 0),
                ),
              )),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 235, 25, 10),
            ),
            onPressed: () async {
              final result =
                  await Provider.of<AuthProvider>(context, listen: false)
                      .customerService
                      .updateCustomer(
                        customerId: customer['id'],
                        nama: namaC.text.trim(),
                        noTelepon: telpC.text.trim(),
                        alamat: alamatC.text.trim().isEmpty
                            ? null
                            : alamatC.text.trim(),
                        email: emailC.text.trim().isEmpty
                            ? null
                            : emailC.text.trim(),
                      );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message'] ?? 'Diperbarui'),
                backgroundColor: result['success']
                    ? Colors.green
                    : const Color.fromARGB(255, 235, 25, 10),
              ));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeletePelangganDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: const Text('Yakin ingin menghapus?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.black))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 235, 25, 10),
            ),
            onPressed: () async {
              final result =
                  await Provider.of<AuthProvider>(context, listen: false)
                      .customerService
                      .deleteCustomer(id);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message'] ?? 'Terhapus'),
                backgroundColor: result['success']
                    ? Colors.green
                    : const Color.fromARGB(255, 235, 25, 10),
              ));
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final namaC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    String jabatan = 'kasir';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: const Text('Tambah Pengguna'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: namaC,
                  decoration: const InputDecoration(
                      labelText: 'Nama *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailC,
                  decoration: const InputDecoration(
                      labelText: 'Email *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: passC,
                  decoration: const InputDecoration(
                      labelText: 'Password *', border: OutlineInputBorder()),
                  obscureText: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: jabatan,
                decoration: const InputDecoration(
                    labelText: 'Jabatan', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir'))
                ],
                onChanged: (v) => setStateDlg(() => jabatan = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: const TextStyle(
                    color: Color.fromARGB(230, 17, 0, 0),
                  ),
                )),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 235, 25, 10),
              ),
              onPressed: () async {
                if (namaC.text.trim().isEmpty ||
                    emailC.text.trim().isEmpty ||
                    passC.text.trim().isEmpty) return;
                final result =
                    await Provider.of<AuthProvider>(context, listen: false)
                        .userService
                        .createUser(
                          email: emailC.text.trim(),
                          password: passC.text,
                          nama: namaC.text.trim(),
                          jabatan: jabatan,
                        );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Sukses'),
                  backgroundColor: result['success']
                      ? Colors.green
                      : const Color.fromARGB(255, 235, 25, 10),
                ));
              },
              child: const Text(
                'Simpan',
                style: const TextStyle(
                  color: Color.fromARGB(230, 17, 0, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final namaC = TextEditingController(text: user['nama']);
    String jabatan = user['jabatan'] ?? 'kasir';
    bool aktif = user['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: const Text('Edit Pengguna'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: namaC,
                  decoration: const InputDecoration(
                      labelText: 'Nama *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: jabatan,
                decoration: const InputDecoration(
                    labelText: 'Jabatan', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir'))
                ],
                onChanged: (v) => setStateDlg(() => jabatan = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                  title: const Text('Status Aktif'),
                  value: aktif,
                  onChanged: (v) => setStateDlg(() => aktif = v)),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final result =
                    await Provider.of<AuthProvider>(context, listen: false)
                        .userService
                        .updateUser(
                          userId: user['id'],
                          nama: namaC.text.trim(),
                          jabatan: jabatan,
                          isActive: aktif,
                        );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? 'Diperbarui'),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red));
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: const Text('Yakin ingin menghapus pengguna ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.black))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final result =
                  await Provider.of<AuthProvider>(context, listen: false)
                      .userService
                      .deleteUser(userId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Terhapus'),
                  backgroundColor:
                      result['success'] ? Colors.green : Colors.red));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
