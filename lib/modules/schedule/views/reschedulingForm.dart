import 'package:flutter/material.dart';

class ReschedulePage extends StatefulWidget {
  final String title;
  final String date; // Format: '2025-03-30'
  final String time; // Format: '8:00 AM - 10:00 AM'

  const ReschedulePage({
    super.key,
    required this.title,
    required this.date,
    required this.time,
  });

  @override
  State<ReschedulePage> createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  @override
  void initState() {
    super.initState();

    selectedDate = _parseDate(widget.date);
    final times = widget.time.split(" - ");
    startTime = _parseTime(times[0]);
    endTime = _parseTime(times[1]);
  }

  DateTime _parseDate(String date) {
    final parts = date.split("-");
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.trim().split(" ");
    final timeParts = parts[0].split(":");
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1].toLowerCase() == 'pm';
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void showConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Confirm Rescheduling"),
        content: Text(
          "You are going to reschedule the task to:\n\n"
          "${_formatDate(selectedDate)}\n"
          "${startTime.format(context)} - ${endTime.format(context)}\n\n"
          "A notification will be sent to your workshop owner.",
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("No"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Rescheduling sent")),
                    );
                  },
                  child: const Text("Yes"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rescheduling"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildField("Task", widget.title),
            GestureDetector(
              onTap: pickDate,
              child: buildField("Date", _formatDate(selectedDate)),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickTime(true),
                    child: buildField("Start Time", startTime.format(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickTime(false),
                    child: buildField("End Time", endTime.format(context)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: showConfirmDialog,
                    child: const Text("Reschedule"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
