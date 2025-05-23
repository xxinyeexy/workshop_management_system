import 'package:flutter/material.dart';

class AssignTaskPage extends StatefulWidget {
  final String foremanName;
  final String workTime;

  const AssignTaskPage({
    super.key,
    required this.foremanName,
    required this.workTime,
  });

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final rewardController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Task"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(widget.foremanName.split(" ").map((e) => e[0]).join())),
              title: Text(widget.foremanName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            buildTextField("Task Assign", titleController),
            buildTextField("Description", descriptionController),
            buildDatePicker("Date", formatDate(selectedDate), pickDate),
            Row(
              children: [
                Expanded(child: buildTimePicker("Start Time", startTime.format(context), () => pickTime(true))),
                const SizedBox(width: 12),
                Expanded(child: buildTimePicker("End Time", endTime.format(context), () => pickTime(false))),
              ],
            ),
            buildTextField("Reward (RM)", rewardController, isCurrency: true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Task Assigned")),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Assign Task"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool isCurrency = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isCurrency ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixText: isCurrency ? "RM " : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDatePicker(String label, String value, VoidCallback onTap) {
    return buildPicker(label, value, onTap, icon: Icons.calendar_today);
  }

  Widget buildTimePicker(String label, String value, VoidCallback onTap) {
    return buildPicker(label, value, onTap, icon: Icons.access_time);
  }

  Widget buildPicker(String label, String value, VoidCallback onTap, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
