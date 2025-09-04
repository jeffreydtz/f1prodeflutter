import 'package:flutter/material.dart';

// Skeleton widgets para mostrar loading de forma más elegante
class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonContainer({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[800]?.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class RaceCardSkeleton extends StatelessWidget {
  const RaceCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonContainer(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonContainer(
                          width: double.infinity, height: 16),
                      const SizedBox(height: 8),
                      SkeletonContainer(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonContainer(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const SkeletonContainer(width: double.infinity, height: 14),
            const SizedBox(height: 16),
            SkeletonContainer(
                width: 120,
                height: 36,
                borderRadius: BorderRadius.circular(18)),
          ],
        ),
      ),
    );
  }
}

class TournamentCardSkeleton extends StatelessWidget {
  const TournamentCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonContainer(width: double.infinity, height: 20),
            const SizedBox(height: 12),
            Row(
              children: [
                const SkeletonContainer(width: 60, height: 14),
                const Spacer(),
                SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.2, height: 14),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SkeletonContainer(width: 80, height: 14),
                const Spacer(),
                SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SkeletonContainer(
              width: 120, height: 120, borderRadius: BorderRadius.circular(60)),
          const SizedBox(height: 16),
          const SkeletonContainer(width: 200, height: 24),
          const SizedBox(height: 8),
          const SkeletonContainer(width: 150, height: 16),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonContainer(width: 120, height: 18),
                  const SizedBox(height: 12),
                  _buildStatSkeleton(),
                  const SizedBox(height: 8),
                  _buildStatSkeleton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonContainer(width: 100, height: 18),
                  const SizedBox(height: 12),
                  _buildListItemSkeleton(),
                  _buildListItemSkeleton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonContainer(width: 120, height: 14),
          SkeletonContainer(width: 60, height: 14),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Row(
        children: [
          SkeletonContainer(width: 24, height: 24),
          SizedBox(width: 16),
          SkeletonContainer(width: 120, height: 16),
          Spacer(),
          SkeletonContainer(width: 16, height: 16),
        ],
      ),
    );
  }
}

class ResultCardSkeleton extends StatelessWidget {
  const ResultCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(width: double.infinity, height: 16),
                      SizedBox(height: 8),
                      SkeletonContainer(width: 200, height: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SkeletonContainer(
                    width: MediaQuery.of(context).size.width * 0.2, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
