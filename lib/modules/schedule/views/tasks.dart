import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/schedule/widgets/taskcard.dart';

class TasksPage extends StatefulWidget{
  const TasksPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TasksPageState();
  }
  
}

class _TasksPageState extends State<TasksPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text('Tasks',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
          const TaskCard(
            title: "Engine Repair",
            subtitle: "Repair the WMS 9011's car engine",
            date: "Sunday, March 30, 2025",
            time: "9:00 AM - 12:00 PM",
            status: "In Progress",
            statusColor: Color(0xFF2D9CDB),
          ),
          const SizedBox(height: 12),
          const TaskCard(
            title: "Bumper Repair",
            subtitle: "Repair the CWS 1654’s car bumper",
            date: "Monday, March 31, 2025",
            time: "10:00 AM – 12:00 PM",
            status: "Scheduled",
            statusColor: Color(0xFF56CCF2),
          ),
        ],
      ),
    );
  }

}