import 'package:flutter/material.dart';

class ForemanCard extends StatelessWidget {
  final String name;
  final String time;
  final String? subtitle;
  final String? status;
  final Color? statusColor;
  final VoidCallback? onTap;

  const ForemanCard({
    super.key,
    required this.name,
    required this.time,
    this.subtitle,
    this.status,
    this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                name.split(" ").map((e) => e[0]).take(2).join(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            if (status != null && statusColor != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor!.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status!,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
