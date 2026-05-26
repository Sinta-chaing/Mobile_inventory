import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/profile_menu_widget.dart';
import '../../services/customer_data_service.dart';
import '../../models/all_models.dart' as backend;

// UI-specific Customer model with extra fields for display
class Customer {
  final int customerId;
  String name;
  String? email;
  String phone;
  String businessAddress;
  String customerType;
  String company; // Maps to businessAddress
  String address;
  double totalPurchases;
  int orderCount;
  DateTime? firstPurchaseDate;
  DateTime joinDate;
  String notes;

  Customer({
    required this.customerId,
    required this.name,
    this.email,
    required this.phone,
    required this.businessAddress,
    required this.customerType,
    String? company,
    String? address,
    this.totalPurchases = 0.0,
    this.orderCount = 0,
    this.firstPurchaseDate,
    DateTime? joinDate,
    this.notes = '',
  }) : company = company ?? businessAddress,
       address = address ?? businessAddress,
       joinDate = joinDate ?? DateTime.now();

  /// Map from backend Customer model to UI Customer
  static Customer fromBackend(backend.Customer customer) {
    return Customer(
      customerId: customer.customerId,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      businessAddress: customer.businessAddress,
      customerType: customer.customerType,
      firstPurchaseDate: customer.firstPurchaseDate,
    );
  }

  /// Convert UI Customer back to backend Customer
  backend.Customer toBackend() {
    return backend.Customer(
      customerId: customerId,
      name: name,
      businessAddress: businessAddress,
      phone: phone,
      email: email,
      customerType: customerType,
      firstPurchaseDate: firstPurchaseDate,
      createdAt: DateTime.now(),
    );
  }
}

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  int _selectedNavIndex = 2;
  String _searchQuery = '';
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final backendCustomers = await CustomerDataService.fetchCustomers();
      final customers = backendCustomers
          .map((c) => Customer.fromBackend(c))
          .toList();
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Customer> get _filteredCustomers {
    return _customers.where((c) {
      final matchSearch =
          _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.businessAddress.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return matchSearch;
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
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.supplierScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.biDashboardScreen);
        break;
    }
  }

  Color _tierColor(int index) {
    final colors = [AppTheme.primary, const Color(0xFF6366F1)];
    return colors[index % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  BoxDecoration _outlinedCardDecoration({double radius = 12}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppTheme.outlineVariant, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildCustomerList()),
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
    final totalRevenue = _customers.fold<double>(
      0,
      (s, c) => s + c.totalPurchases,
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
                  Icons.people_rounded,
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
                      'Customers',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C2B),
                      ),
                    ),
                    Text(
                      'Manage customer records',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const ProfileMenuWidget(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${_customers.length}',
                  Icons.people_outline_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${_customers.fold<int>(0, (s, c) => s + c.orderCount)}',
                  Icons.shopping_bag_outlined,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  '\$${(totalRevenue / 1000).toStringAsFixed(1)}k',
                  Icons.trending_up_rounded,
                  AppTheme.success,
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
          decoration: _outlinedCardDecoration(radius: 14),
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
            decoration: _outlinedCardDecoration(radius: 14),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF1A1C2B),
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, company or email…',
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

  Widget _buildCustomerList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final customers = _filteredCustomers;
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: AppTheme.outline.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No customers found',
              style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _buildCustomerCard(customers[i]),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final tierColor = _tierColor(_customers.indexOf(customer));
    return GestureDetector(
      onTap: () => _showCustomerDetail(customer),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: _outlinedCardDecoration(radius: 16),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tierColor.withAlpha(200), tierColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.0),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials(customer.name),
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
                      Text(
                        customer.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C2B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.company,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 11,
                            color: AppTheme.outline,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              customer.email ?? 'N/A',
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
                          _InfoChip(
                            label: '${customer.orderCount} orders',
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          _InfoChip(
                            label:
                                '\$${(customer.totalPurchases / 1000).toStringAsFixed(1)}k spent',
                            color: AppTheme.success,
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

  void _showCustomerDetail(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(
        customer: customer,
        onEdit: (updated) {
          setState(() {
            final idx = _customers.indexWhere(
              (c) => c.customerId == updated.customerId,
            );
            if (idx >= 0) _customers[idx] = updated;
          });
          Navigator.pop(context);
        },
        onDelete: () {
          setState(
            () => _customers.removeWhere(
              (c) => c.customerId == customer.customerId,
            ),
          );
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
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'Add Customer',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Customer',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
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
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Company'),
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
            onPressed: () async {
              if (nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer name is required')),
                );
                return;
              }

              // Call backend API to create customer
              final result = await CustomerDataService.createCustomer({
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'phone': phoneCtrl.text,
                'businessAddress': companyCtrl.text.isNotEmpty
                    ? companyCtrl.text
                    : addressCtrl.text,
                'customerType': 'Individual',
              });

              if (result != null) {
                // Success! Add to UI
                if (mounted) {
                  setState(() {
                    _customers.insert(0, Customer.fromBackend(result));
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Customer "${result.name}" created successfully',
                      ),
                    ),
                  );
                }
              } else {
                // Error creating customer
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create customer')),
                  );
                }
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

class _CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final ValueChanged<Customer> onEdit;
  final VoidCallback onDelete;

  const _CustomerDetailSheet({
    required this.customer,
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
                            customer.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            customer.company,
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
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: customer.email ?? 'N/A',
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: customer.phone,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: customer.address,
                ),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Member Since',
                  value:
                      '${customer.joinDate.day}/${customer.joinDate.month}/${customer.joinDate.year}',
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
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${customer.orderCount}',
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
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '\$${customer.totalPurchases.toStringAsFixed(0)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              'Total Spent',
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
                if (customer.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Text(
                      customer.notes,
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
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final companyCtrl = TextEditingController(text: customer.company);
    final notesCtrl = TextEditingController(text: customer.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Customer',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
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
                controller: companyCtrl,
                decoration: const InputDecoration(labelText: 'Company'),
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
              customer.name = nameCtrl.text;
              customer.email = emailCtrl.text;
              customer.phone = phoneCtrl.text;
              customer.company = companyCtrl.text;
              customer.notes = notesCtrl.text;
              onEdit(customer);
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
