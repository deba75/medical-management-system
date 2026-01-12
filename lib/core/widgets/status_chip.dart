import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AppointmentStatus.upcoming:
        backgroundColor = AppTheme.upcomingColor.withOpacity(0.1);
        textColor = AppTheme.upcomingColor;
        text = 'Upcoming';
        break;
      case AppointmentStatus.completed:
        backgroundColor = AppTheme.completedColor.withOpacity(0.1);
        textColor = AppTheme.completedColor;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        backgroundColor = AppTheme.cancelledColor.withOpacity(0.1);
        textColor = AppTheme.cancelledColor;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RequestStatusChip extends StatelessWidget {
  final String status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppTheme.pendingColor.withOpacity(0.1);
        textColor = AppTheme.pendingColor;
        text = 'Pending';
        break;
      case 'accepted':
        backgroundColor = AppTheme.upcomingColor.withOpacity(0.1);
        textColor = AppTheme.upcomingColor;
        text = 'Accepted';
        break;
      case 'onroute':
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        text = 'On Route';
        break;
      case 'completed':
        backgroundColor = AppTheme.completedColor.withOpacity(0.1);
        textColor = AppTheme.completedColor;
        text = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppTheme.cancelledColor.withOpacity(0.1);
        textColor = AppTheme.cancelledColor;
        text = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
