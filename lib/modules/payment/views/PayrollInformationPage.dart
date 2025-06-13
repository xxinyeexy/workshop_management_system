import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../sidebar.dart';
import 'package:workshop_management_system/modules/payment/views/PayrollProcessPage.dart';
//import 'package:workshop_management_system/modules/payment/views/PayrollInvoicePage.dart';

class PayrollInformationPage extends StatefulWidget {
  final String role; // "foreman" or "workshop_owner"

  const PayrollInformationPage({Key? key, required this.role}) : super(key: key);

  @override
  State<PayrollInformationPage> createState() => _PayrollInformationPageState();
}

class _PayrollInformationPageState extends State<PayrollInformationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get isForeman => widget.role.toLowerCase() == "foreman";

  Color get primaryColor {
    return isForeman
        ? const Color(0xFF2FB668) // green
        : const Color(0xFF4260DB); // blue
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEarningsCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 4),
          Text('RM${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('This Month', style: TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = isForeman
        ? const [Tab(text: "Completed Jobs"), Tab(text: "Payment History")]
        : const [Tab(text: "Pending Approvals"), Tab(text: "Completed Payroll")];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(isForeman ? "My Payroll" : "Manage Payroll", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          _buildEarningsCard(
            isForeman ? "Total Earnings" : "Total Payroll",
            isForeman ? 250.75 : 12750.50,
            primaryColor,
          ),
          TabBar(
            controller: _tabController,
            tabs: tabs,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: isForeman
                  ? [_buildCompletedJobsTab(), _buildPaymentHistoryTab()]
                  : [_buildPendingApprovalsTab(), _buildCompletedPayrollTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildJobCard("Engine Repair", "Wilson Auto Repairs", 37.50),
        _buildJobCard("Brake Replacement", "Smith’s Auto Shop", 18.00),
      ],
    );
  }

  Widget _buildPaymentHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompletedPayrollCard("Engine Repair", "Wilson Auto Repairs", 37.50),
        _buildCompletedPayrollCard("Brake Replacement", "Smith’s Auto Shop", 18.00),
      ],
    );
  }

  Widget _buildPendingApprovalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildApprovalCard("Mike Johnson", "Engine Repair", 37.50),
        _buildApprovalCard("Sarah Lee", "Brake Replacement", 18.00),
      ],
    );
  }

  Widget _buildCompletedPayrollTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompletedPayrollCard("Engine Repair", "Mike Johnson", 37.50),
        _buildCompletedPayrollCard("Brake Replacement", "Sarah Lee", 18.00),
      ],
    );
  }

  Widget _buildJobCard(String title, String workshop, double amount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(workshop, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("RM${amount.toStringAsFixed(2)}",
                    style: TextStyle(color: primaryColor, fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(100, 30),
                  ),
                  child: const Text("Mark Complete", style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(String name, String jobTitle, double amount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Text(name.split(' ').map((e) => e[0]).take(2).join()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(jobTitle, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("RM${amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        bool isApproved = false;
                        String initials = name.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 500),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 16),
                                            Center(
                                              child: CircleAvatar(
                                                radius: 30,
                                                child: Text(initials),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            _infoRowDialog('Foreman', name),
                                            _infoRowDialog('Task', jobTitle),
                                            _infoRowDialog('Bank Account Number', '123-456-789'),
                                            _infoRowDialog('Bank Name', 'Maybank'),
                                            _infoRowDialog('Hours', '3'),
                                            _infoRowDialog('Total Amount', 'RM${amount.toStringAsFixed(2)}', highlight: true),
                                            const SizedBox(height: 20),
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context); // close the dialog
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => PayrollProcessPage(
                                                        amount: (amount * 100).toInt(), // cents
                                                        currency: 'myr',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Confirm Payment'),
                                              ),
                                            ),

                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(100, 30),
                  ),
                  child: const Text("Approve", style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedPayrollCard(String jobTitle, String name, double amount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text("Payroll Invoice", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("RM${amount.toStringAsFixed(2)}", style: TextStyle(color: primaryColor, fontSize: 16)),
                const SizedBox(height: 4),
                const Text("Completed", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(100, 30),
                  ),
                  child: const Text("Download", style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRowDialog(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
