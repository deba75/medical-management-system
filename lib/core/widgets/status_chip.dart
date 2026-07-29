import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.upcoming:
        color = AppTheme.upcomingColor;
        text = 'Upcoming';
        break;
      case AppointmentStatus.completed:
        color = AppTheme.completedColor;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = AppTheme.cancelledColor;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestStatusChip extends StatelessWidget {
  final String status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppTheme.pendingColor;
        text = 'Pending';
        break;
      case 'accepted':
        color = AppTheme.upcomingColor;
        text = 'Accepted';
        break;
      case 'onroute':
        color = AppTheme.primaryColor;
        text = 'On Route';
        break;
      case 'completed':
        color = AppTheme.completedColor;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppTheme.cancelledColor;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
