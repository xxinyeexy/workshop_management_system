import 'package:flutter/material.dart';

class SimpleForemanCard extends StatelessWidget {
  final String name;

  const SimpleForemanCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(" ").map((e) => e[0]).take(2).join().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Foreman", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
