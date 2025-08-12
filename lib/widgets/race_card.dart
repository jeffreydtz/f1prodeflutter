import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/race.dart';
import '../theme/f1_theme.dart';
import 'f1_widgets.dart';

class RaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback onPredict;
  final VoidCallback onViewResults;

  const RaceCard({
    Key? key,
    required this.race,
    required this.onPredict,
    required this.onViewResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final raceDate = DateTime.parse(race.date);
    final isCompleted = race.hasBet;
    final now = DateTime.now();
    final isUpcoming = raceDate.isAfter(now);

    return F1RaceCard(
      onTap: isCompleted ? onViewResults : onPredict,
      accentColor: isCompleted ? F1Theme.successGreen : F1Theme.f1Red,
      showCheckeredFlag: isCompleted,
      margin: const EdgeInsets.symmetric(
          horizontal: F1Theme.s, vertical: F1Theme.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with race name and status indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  race.name,
                  style: F1Theme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (race.hasSprint)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: F1Theme.s,
                    vertical: F1Theme.xs,
                  ),
                  decoration: BoxDecoration(
                    color: F1Theme.safetyYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(F1Theme.radiusS),
                    border: Border.all(
                      color: F1Theme.safetyYellow,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'SPRINT',
                    style: F1Theme.labelSmall.copyWith(
                      color: F1Theme.safetyYellow,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: F1Theme.m),

          // Race details
          _buildRaceDetail(
            context,
            icon: Icons.location_on_outlined,
            label: 'Circuito',
            value: race.circuit,
          ),

          const SizedBox(height: F1Theme.s),

          _buildRaceDetail(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: DateFormat('dd/MM/yyyy').format(raceDate),
            trailing: _buildTimeRemaining(raceDate, isUpcoming),
          ),

          const SizedBox(height: F1Theme.s),

          _buildRaceDetail(
            context,
            icon: Icons.sports_motorsports_outlined,
            label: 'Temporada',
            value: '${race.season} - Ronda ${race.round}',
          ),

          const SizedBox(height: F1Theme.l),

          // Action button
          F1PrimaryButton(
            text: isCompleted ? 'Ver tu Predicción' : 'Predecir',
            onPressed: isCompleted ? onViewResults : onPredict,
            icon: isCompleted ? Icons.visibility : Icons.sports_score,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRaceDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: F1Theme.textGrey,
        ),
        const SizedBox(width: F1Theme.s),
        Text(
          '$label: ',
          style: F1Theme.bodySmall.copyWith(
            color: F1Theme.textGrey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: F1Theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget? _buildTimeRemaining(DateTime raceDate, bool isUpcoming) {
    if (!isUpcoming) return null;

    final now = DateTime.now();
    final difference = raceDate.difference(now);

    if (difference.inDays > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: F1Theme.s,
          vertical: F1Theme.xs,
        ),
        decoration: BoxDecoration(
          color: F1Theme.f1Red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(F1Theme.radiusS),
        ),
        child: Text(
          '${difference.inDays}d',
          style: F1Theme.labelSmall.copyWith(
            color: F1Theme.f1Red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (difference.inHours > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: F1Theme.s,
          vertical: F1Theme.xs,
        ),
        decoration: BoxDecoration(
          color: F1Theme.warningOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(F1Theme.radiusS),
        ),
        child: Text(
          '${difference.inHours}h',
          style: F1Theme.labelSmall.copyWith(
            color: F1Theme.warningOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return null;
  }
}
