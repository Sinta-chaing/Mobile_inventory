import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';

enum SupplierStatus { active, inactive, onHold }

class Supplier {
  final String id;
  String name;
  String contactPerson;
  String email;
  String phone;
  String address;
  String category;
  SupplierStatus status;
  double totalOrders;
  int orderCount;
  double rating;
  int leadTimeDays;
  String notes;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.category,
    required this.status,
    required this.totalOrders,
    required this.orderCount,
    required this.rating,
    required this.leadTimeDays,
    this.notes = '',
  });
}

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  int _selectedNavIndex = 3;
  String _searchQuery = '';
  SupplierStatus? _filterStatus;

  final List<Supplier> _suppliers = [
    Supplier(
      id: 'S001',
      name: 'ProTools Supply Co.',
      contactPerson: 'James Wilson',
      email: 'sales@protools.com',
      phone: '+1 (555) 100-2000',
      address: '100 Industrial Way, Chicago, IL 60601',
      category: 'Power Tools',
      status: SupplierStatus.active,
      totalOrders: 125400.00,
      orderCount: 28,
      rating: 4.8,
      leadTimeDays: 5,
      notes: 'Preferred supplier for power tools',
    ),
    Supplier(
      id: 'S002',
      name: 'Meridian Hardware Dist.',
      contactPerson: 'Patricia Lee',
      email: 'orders@meridian.com',
      phone: '+1 (555) 200-3000',
      address: '200 Commerce Blvd, Detroit, MI 48201',
      category: 'Hand Tools',
      status: SupplierStatus.active,
      totalOrders: 67800.50,
      orderCount: 19,
      rating: 4.5,
      leadTimeDays: 7,
      notes: '',
    ),
    Supplier(
      id: 'S003',
      name: 'SafeGuard Industrial',
      contactPerson: 'Thomas Brown',
      email: 'supply@safeguard.com',
      phone: '+1 (555) 300-4000',
      address: '300 Safety Pkwy, Cleveland, OH 44101',
      category: 'Safety Equipment',
      status: SupplierStatus.active,
      totalOrders: 34200.00,
      orderCount: 12,
      rating: 4.2,
      leadTimeDays: 10,
      notes: 'Certified safety equipment supplier',
    ),
    Supplier(
      id: 'S004',
      name: 'TechMeasure Solutions',
      contactPerson: 'Angela Davis',
      email: 'info@techmeasure.com',
      phone: '+1 (555) 400-5000',
      address: '400 Tech Drive, Columbus, OH 43201',
      category: 'Measuring Tools',
      status: SupplierStatus.onHold,
      totalOrders: 18900.00,
      orderCount: 8,
      rating: 3.8,
      leadTimeDays: 14,
      notes: 'On hold pending contract renewal',
    ),
    Supplier(
      id: 'S005',
      name: 'FastFix Distributors',
      contactPerson: 'Michael Scott',
      email: 'orders@fastfix.com',
      phone: '+1 (555) 500-6000',
      address: '500 Logistics Ave, Indianapolis, IN 46201',
      category: 'General Hardware',
      status: SupplierStatus.inactive,
      totalOrders: 5600.00,
      orderCount: 4,
      rating: 3.2,
      leadTimeDays: 21,
      notes: 'Inactive - poor delivery performance',
    ),
  ];

  List<Supplier> get _filteredSuppliers {
    return _suppliers.where((s) {
      final matchSearch =
          _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _filterStatus == null || s.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.inventoryScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.purchaseScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.customerScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.biDashboardScreen);
        break;
    }
  }

  Color _statusColor(SupplierStatus s) {
    switch (s) {
      case SupplierStatus.active:
        return AppTheme.success;
      case SupplierStatus.inactive:
        return AppTheme.error;
      case SupplierStatus.onHold:
        return AppTheme.warning;
    }
  }

  String _statusLabel(SupplierStatus s) {
    switch (s) {
      case SupplierStatus.active:
        return 'Active';
      case SupplierStatus.inactive:
        return 'Inactive';
      case SupplierStatus.onHold:
        return 'On Hold';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildSupplierList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildGlassNavBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(20),
              border: Border(
                top: BorderSide(
                  color: AppTheme.outlineVariant.withAlpha(100),
                  width: 1,
                ),
              ),
            ),
            child: AppNavigation(
              currentIndex: _selectedNavIndex,
              onDestinationSelected: _onNavTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final active = _suppliers
        .where((s) => s.status == SupplierStatus.active)
        .length;
    final totalValue = _suppliers.fold<double>(
      0,
      (s, sup) => s + sup.totalOrders,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suppliers',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      'Manage supplier records',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_suppliers.length}',
                  Icons.business_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '$active',
                  Icons.check_circle_rounded,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Purchased',
                  '\$${(totalValue / 1000).toStringAsFixed(0)}k',
                  Icons.attach_money_rounded,
                  AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppTheme.glassCardDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassCardDecoration,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF1A1C2B),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, category or contact…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.outline,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.outline,
                  size: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierList() {
    final suppliers = _filteredSuppliers;
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: AppTheme.outline.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No suppliers found',
              style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildSupplierCard(suppliers[i]),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    final statusColor = _statusColor(supplier.status);
    return GestureDetector(
      onTap: () => _showSupplierDetail(supplier),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassCardDecoration,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withAlpha(180),
                        AppTheme.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials(supplier.name),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C2B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: statusColor.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              _statusLabel(supplier.status),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        supplier.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              supplier.contactPerson,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppTheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRatingStars(supplier.rating),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: '${supplier.leadTimeDays}d lead',
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          _InfoChip(
                            label: '${supplier.orderCount} orders',
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor()
              ? Icons.star_rounded
              : (i < rating
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
          size: 12,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }

  void _showSupplierDetail(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierDetailSheet(
        supplier: supplier,
        onEdit: (updated) {
          setState(() {
            final idx = _suppliers.indexWhere((s) => s.id == updated.id);
            if (idx >= 0) _suppliers[idx] = updated;
          });
          Navigator.pop(context);
        },
        onDelete: () {
          setState(() => _suppliers.removeWhere((s) => s.id == supplier.id));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddSupplierDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: Text(
          'Add Supplier',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Supplier',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _suppliers.insert(
                    0,
                    Supplier(
                      id: 'S${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      contactPerson: contactCtrl.text,
                      email: emailCtrl.text,
                      phone: phoneCtrl.text,
                      address: addressCtrl.text,
                      category: categoryCtrl.text.isEmpty
                          ? 'General'
                          : categoryCtrl.text,
                      status: SupplierStatus.active,
                      totalOrders: 0,
                      orderCount: 0,
                      rating: 4.0,
                      leadTimeDays: 7,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SupplierDetailSheet extends StatelessWidget {
  final Supplier supplier;
  final ValueChanged<Supplier> onEdit;
  final VoidCallback onDelete;

  const _SupplierDetailSheet({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            supplier.category,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => _showEditDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Contact',
                  value: supplier.contactPerson,
                ),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: supplier.email,
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: supplier.phone,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: supplier.address,
                ),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Lead Time',
                  value: '${supplier.leadTimeDays} days',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${supplier.orderCount}',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Orders',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(10),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '\$${(supplier.totalOrders / 1000).toStringAsFixed(1)}k',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              'Total Purchased',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withAlpha(15),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          children: [
                            Text(
                              supplier.rating.toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFC107),
                              ),
                            ),
                            Text(
                              'Rating',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (supplier.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      supplier.notes,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF3F4460),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: supplier.name);
    final contactCtrl = TextEditingController(text: supplier.contactPerson);
    final emailCtrl = TextEditingController(text: supplier.email);
    final phoneCtrl = TextEditingController(text: supplier.phone);
    final notesCtrl = TextEditingController(text: supplier.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Supplier',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              supplier.name = nameCtrl.text;
              supplier.contactPerson = contactCtrl.text;
              supplier.email = emailCtrl.text;
              supplier.phone = phoneCtrl.text;
              supplier.notes = notesCtrl.text;
              onEdit(supplier);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.outline),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1C2B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
