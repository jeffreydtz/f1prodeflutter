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
    final now = DateTime.now();
    final timeUntil = raceDate.difference(now);

    final hasBet = race.hasBet;
    final isUpcoming = !timeUntil.isNegative;
    final isRaceCompleted = race.completed;
    final isLive = !isUpcoming && !isRaceCompleted;

    final Color accent = hasBet
        ? F1Theme.successGreen
        : isRaceCompleted
            ? F1Theme.silverSecond
            : isLive
                ? F1Theme.safetyYellow
                : F1Theme.f1Red;

    final String statusLabel = hasBet
        ? 'Predicción enviada'
        : isRaceCompleted
            ? 'Resultados disponibles'
            : isLive
                ? 'Carrera en vivo'
                : 'Apuestas abiertas';

    final IconData statusIcon = hasBet
        ? Icons.check_circle_rounded
        : isRaceCompleted
            ? Icons.flag_rounded
            : isLive
                ? Icons.podcasts
                : Icons.flash_on_rounded;

    final VoidCallback? primaryAction =
        hasBet ? onViewResults : (isRaceCompleted ? null : onPredict);

    final String actionLabel = hasBet
        ? 'Ver tu predicción'
        : isRaceCompleted
            ? 'Carrera finalizada'
            : 'Predecir resultado';

    final IconData actionIcon = hasBet
        ? Icons.visibility_rounded
        : isRaceCompleted
            ? Icons.flag_circle
            : Icons.sports_score;

    final String formattedDate = DateFormat('dd MMM yyyy').format(raceDate);
    final String countdownLabel = isUpcoming
        ? timeUntil.inDays > 0
            ? '${timeUntil.inDays} días'
            : timeUntil.inHours > 0
                ? '${timeUntil.inHours} horas'
                : '${timeUntil.inMinutes <= 0 ? 0 : timeUntil.inMinutes} min'
        : isRaceCompleted
            ? 'Finalizada'
            : 'En vivo';

    return F1RaceCard(
      onTap: hasBet ? onViewResults : (isRaceCompleted ? null : onPredict),
      accentColor: accent,
      showCheckeredFlag: hasBet || isRaceCompleted,
      margin: const EdgeInsets.symmetric(
        horizontal: F1Theme.s,
        vertical: F1Theme.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  race.name,
                  style: F1Theme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: F1Theme.s),
              if (race.hasSprint)
                _buildHighlightBadge('Sprint', F1Theme.safetyYellow),
            ],
          ),
          const SizedBox(height: F1Theme.m),
          Wrap(
            spacing: F1Theme.s,
            runSpacing: F1Theme.s,
            children: [
              _buildStatusChip(statusLabel, statusIcon, accent),
              if (isUpcoming)
                _buildStatusChip('Faltan $countdownLabel', Icons.timelapse,
                    F1Theme.telemetryTeal),
              if (isLive)
                _buildStatusChip(
                  'En vivo',
                  Icons.radio_button_checked,
                  F1Theme.safetyYellow,
                ),
            ],
          ),
          const SizedBox(height: F1Theme.m),
          Wrap(
            spacing: F1Theme.m,
            runSpacing: F1Theme.m,
            children: [
              _buildMetaTile(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha',
                value: formattedDate,
              ),
              _buildMetaTile(
                icon: Icons.sports_motorsports_outlined,
                label: 'Temporada',
                value: '${race.season} · Ronda ${race.round}',
              ),
              _buildMetaTile(
                icon: Icons.location_on_outlined,
                label: 'Circuito',
                value: race.circuit,
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: F1Theme.m),
            _buildCountdownSection(raceDate),
          ],
          const SizedBox(height: F1Theme.l),
          F1PrimaryButton(
            text: actionLabel,
            onPressed: primaryAction,
            icon: actionIcon,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: F1Theme.m,
        vertical: F1Theme.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(F1Theme.radiusXL),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: F1Theme.xs),
          Text(
            label,
            style: F1Theme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.all(F1Theme.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(F1Theme.radiusL),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: F1Theme.textGrey,
                ),
                const SizedBox(width: F1Theme.s),
                Text(
                  label,
                  style: F1Theme.labelSmall.copyWith(
                    color: F1Theme.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: F1Theme.xs),
            Text(
              value,
              style: F1Theme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownSection(DateTime raceDate) {
    final now = DateTime.now();
    final timeUntil = raceDate.difference(now);
    const totalWindow = Duration(days: 10);
    double ratio = 1 - (timeUntil.inSeconds / totalWindow.inSeconds);
    if (timeUntil.isNegative) {
      ratio = 1;
    } else {
      ratio = ratio.clamp(0.0, 1.0);
    }

    final String label = timeUntil.inDays > 0
        ? '${timeUntil.inDays} días para el GP'
        : timeUntil.inHours > 0
            ? '${timeUntil.inHours} horas para el GP'
            : '${timeUntil.inMinutes <= 0 ? 0 : timeUntil.inMinutes} minutos para el GP';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: F1Theme.labelSmall.copyWith(
            color: F1Theme.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: F1Theme.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(F1Theme.radiusM),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(F1Theme.f1Red),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: F1Theme.s,
        vertical: F1Theme.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(F1Theme.radiusM),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
        color: color.withOpacity(0.18),
      ),
      child: Text(
        text.toUpperCase(),
        style: F1Theme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
