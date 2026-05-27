// lib/presentation/widgets/ticket_balance_widget.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';

class TicketBalanceWidget extends StatelessWidget {
  final bool showLabel;
  final Color? textColor;
  final double fontSize;

  const TicketBalanceWidget({
    super.key,
    this.showLabel = true,
    this.textColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return GestureDetector(
          onTap: () {
            // Charger le solde quand on tape dessus
            ticketProvider.loadBalance();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: textColor ?? Colors.white,
                  size: fontSize + 2,
                ),
                const SizedBox(width: 6),
                Text(
                  showLabel
                      ? '${ticketProvider.ticketBalance} tickets'
                      : '${ticketProvider.ticketBalance}',
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget pour l'AppBar
class AppBarTicketBalance extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const AppBarTicketBalance({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(child: TicketBalanceWidget()),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Widget compact pour le solde
class CompactTicketBalance extends StatelessWidget {
  const CompactTicketBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.confirmation_number,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${ticketProvider.ticketBalance}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
