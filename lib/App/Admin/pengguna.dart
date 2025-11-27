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
  
  List<Map<String, dynamic>> pelangganList = [];
  List<Map<String, dynamic>> penggunaList = [];
  bool isLoading = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  // Fungsi untuk cek role user
  Future<void> _checkUserRole() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final currentUser = await authProvider.userService.getCurrentUser();
      if (currentUser != null && currentUser['jabatan'] == 'admin') {
        setState(() {
          isAdmin = true;
        });
        _loadData();
      } else {
        setState(() {
          isAdmin = false;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Hanya load data jika user adalah admin
      pelangganList = await authProvider.customerService.getAllCustomers();
      penggunaList = await authProvider.userService.getAllUsers();
      
      debugPrint('✅ Loaded ${pelangganList.length} pelanggan, ${penggunaList.length} users');
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manajemen Data', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Tab Bar - hanya tampil untuk admin
          if (isAdmin) ...[
            Container(
              color: Colors.red,
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
          ],
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContentBasedOnRole(),
          ),
        ],
      ),
      floatingActionButton: isAdmin ? _buildFloatingActionButton() : null,
    );
  }

  // Widget untuk menampilkan content berdasarkan role
  Widget _buildContentBasedOnRole() {
    if (!isAdmin) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Akses Ditolak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Hanya admin yang dapat mengakses halaman ini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPelangganList(),
        _buildPenggunaList(),
      ],
    );
  }

  // Floating Action Button hanya untuk admin
  Widget? _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddDialog,
      backgroundColor: Colors.red,
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }

  Widget _buildPelangganList() {
    if (pelangganList.isEmpty) {
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
      itemCount: pelangganList.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(pelangganList[index], index);
      },
    );
  }

  Widget _buildPenggunaList() {
    if (penggunaList.isEmpty) {
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
      itemCount: penggunaList.length,
      itemBuilder: (context, index) {
        return _buildUserCard(penggunaList[index], index);
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person_outline, color: Colors.red[700]),
        ),
        title: Text(
          customer['nama'] ?? 'Tanpa Nama',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          customer['no_telepon'] ?? '-',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                _showDeletePelangganDialog(customer['id'], index);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () {
                _showEditPelangganDialog(customer, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person_outline, color: Colors.red[700]),
        ),
        title: Text(
          user['nama'] ?? 'Tanpa Nama',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${user['jabatan'] ?? '-'} • ${user['email'] ?? '-'}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.grey),
          onPressed: () {
            _showEditUserDialog(user, index);
          },
        ),
      ),
    );
  }

  void _showAddDialog() {
    if (!isAdmin) return;
    
    if (_tabController.index == 0) {
      _showAddPelangganDialog();
    } else {
      _showAddUserDialog();
    }
  }

  // ========== PELANGGAN CRUD ==========
  
  void _showAddPelangganDialog() {
    if (!isAdmin) return;
    
    final namaController = TextEditingController();
    final noTeleponController = TextEditingController();
    final alamatController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noTeleponController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isAdmin) return;
              
              if (namaController.text.isEmpty || noTeleponController.text.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama dan No. Telepon wajib diisi')),
                  );
                }
                return;
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final result = await authProvider.customerService.createCustomer(
                nama: namaController.text.trim(),
                noTelepon: noTeleponController.text.trim(),
                alamat: alamatController.text.trim().isEmpty ? null : alamatController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context);
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Berhasil')),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Gagal'), 
                      backgroundColor: Colors.red
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 241, 24, 8)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditPelangganDialog(Map<String, dynamic> customer, int index) {
    if (!isAdmin) return;
    
    final namaController = TextEditingController(text: customer['nama']);
    final noTeleponController = TextEditingController(text: customer['no_telepon']);
    final alamatController = TextEditingController(text: customer['alamat'] ?? '');
    final emailController = TextEditingController(text: customer['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noTeleponController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isAdmin) return;
              
              if (namaController.text.isEmpty || noTeleponController.text.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama dan No. Telepon wajib diisi')),
                  );
                }
                return;
              }

              // Update lokal sementara
              setState(() {
                pelangganList[index]['nama'] = namaController.text.trim();
                pelangganList[index]['no_telepon'] = noTeleponController.text.trim();
                pelangganList[index]['alamat'] = alamatController.text.trim();
                pelangganList[index]['email'] = emailController.text.trim();
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pelanggan berhasil diupdate')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 241, 24, 8)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeletePelangganDialog(String customerId, int index) {
    if (!isAdmin) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isAdmin) return;
              
              // Hapus lokal sementara
              setState(() {
                pelangganList.removeAt(index);
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pelanggan berhasil dihapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor:  const Color.fromARGB(255, 241, 24, 8)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ========== USER CRUD ==========
  
  void _showAddUserDialog() {
    if (!isAdmin) return;
    
    final namaController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedJabatan = 'kasir';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Pengguna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedJabatan,
                  decoration: const InputDecoration(
                    labelText: 'Jabatan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedJabatan = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isAdmin) return;
                
                if (namaController.text.isEmpty || 
                    emailController.text.isEmpty || 
                    passwordController.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field wajib diisi')),
                    );
                  }
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final result = await authProvider.userService.createUser(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  nama: namaController.text.trim(),
                  jabatan: selectedJabatan,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Berhasil')),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Gagal'), 
                        backgroundColor: const Color.fromARGB(255, 241, 24, 8)
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor:  const Color.fromARGB(255, 241, 24, 8)),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user, int index) {
    if (!isAdmin) return;
    
    final namaController = TextEditingController(text: user['nama']);
    String selectedJabatan = user['jabatan'] ?? 'kasir';
    bool isActive = user['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Pengguna'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedJabatan,
                  decoration: const InputDecoration(
                    labelText: 'Jabatan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedJabatan = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!isAdmin) return;
                
                if (namaController.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama wajib diisi')),
                    );
                  }
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final result = await authProvider.userService.updateUser(
                  userId: user['id'],
                  nama: namaController.text.trim(),
                  jabatan: selectedJabatan,
                  isActive: isActive,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Berhasil')),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Gagal'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}