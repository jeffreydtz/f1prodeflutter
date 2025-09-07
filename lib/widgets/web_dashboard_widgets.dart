import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/f1_theme.dart';
import '../models/race.dart';
import '../models/tournament.dart';

/// Card moderno para el dashboard web
class ModernDashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final Color? accentColor;
  final VoidCallback? onTap;

  const ModernDashboardCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
    this.accentColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: F1Theme.borderGrey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: F1Theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accentColor ?? Colors.white,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: F1Theme.bodySmall.copyWith(
                                color: F1Theme.textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
                const SizedBox(height: 20),
                
                // Content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid de estadísticas para el dashboard
class StatsGrid extends StatelessWidget {
  final List<StatCard> stats;

  const StatsGrid({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }
}

/// Card individual de estadística
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositiveTrend;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositiveTrend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.arrow_down,
                        color: isPositiveTrend ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: F1Theme.bodySmall.copyWith(
                          color: isPositiveTrend ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: F1Theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: F1Theme.bodySmall.copyWith(
              color: F1Theme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de carrera moderna para web
class ModernRaceCard extends StatelessWidget {
  final Race race;
  final VoidCallback? onPredict;
  final VoidCallback? onViewResults;

  const ModernRaceCard({
    Key? key,
    required this.race,
    this.onPredict,
    this.onViewResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a1a),
            const Color(0xFF111111),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: F1Theme.borderGrey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    F1Theme.f1Red.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con flag de país
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: F1Theme.f1Red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: F1Theme.f1Red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Round ${race.round}',
                        style: F1Theme.bodySmall.copyWith(
                          color: F1Theme.f1Red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (race.hasBet)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.check_mark,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Nombre del GP
                Text(
                  race.name,
                  style: F1Theme.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Circuito
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      color: F1Theme.textGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        race.circuit,
                        style: F1Theme.bodyMedium.copyWith(
                          color: F1Theme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Fecha
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      color: F1Theme.textGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      race.date,
                      style: F1Theme.bodyMedium.copyWith(
                        color: F1Theme.textGrey,
                      ),
                    ),
                  ],
                ),
                
                if (race.hasSprint) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.speedometer,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sprint Weekend',
                          style: F1Theme.bodySmall.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: race.hasBet ? onViewResults : onPredict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: race.hasBet
                          ? Colors.blue.withValues(alpha: 0.2)
                          : F1Theme.f1Red.withValues(alpha: 0.9),
                      foregroundColor: race.hasBet ? Colors.blue : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: race.hasBet
                              ? Colors.blue.withValues(alpha: 0.3)
                              : F1Theme.f1Red,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          race.hasBet
                              ? CupertinoIcons.chart_bar
                              : CupertinoIcons.add,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          race.hasBet ? 'Ver Resultados' : 'Hacer Predicción',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de torneos moderna
class ModernTournamentsList extends StatelessWidget {
  final List<Tournament> tournaments;
  final Function(Tournament) onTournamentTap;

  const ModernTournamentsList({
    Key? key,
    required this.tournaments,
    required this.onTournamentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: tournaments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return _ModernTournamentCard(
          tournament: tournament,
          onTap: () => onTournamentTap(tournament),
        );
      },
    );
  }
}

class _ModernTournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _ModernTournamentCard({
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a1a),
            const Color(0xFF111111),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: F1Theme.borderGrey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: F1Theme.f1RedGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.flag,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: F1Theme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tournament.participants.length} participantes',
                        style: F1Theme.bodyMedium.copyWith(
                          color: F1Theme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Posición #${tournament.userPosition}',
                      style: F1Theme.bodySmall.copyWith(
                        color: F1Theme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournament.userPoints} pts',
                      style: F1Theme.titleMedium.copyWith(
                        color: F1Theme.f1Red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                Icon(
                  CupertinoIcons.chevron_right,
                  color: F1Theme.textGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}