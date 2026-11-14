import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formats.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shop_widgets.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, size: 19, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Laporan Mitra',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RevenueCard(provider: provider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.receipt_long_outlined,
                  label: 'Pesanan Selesai',
                  value: '${provider.completedToday.length}',
                  unit: 'hari ini',
                  color: AppColors.primary,
                  background: AppColors.dangerSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.eco_outlined,
                  label: 'Porsi Diselamatkan',
                  value: '${provider.savedPortionsToday}',
                  unit: 'porsi',
                  color: AppColors.textGreen,
                  background: AppColors.badgeGreenBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stok Tersisa',
                  value: '${provider.stockPortions}',
                  unit: 'porsi',
                  color: AppColors.orange,
                  background: AppColors.orangeSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Menu Aktif',
                  value: '${provider.availableProducts.length}',
                  unit: 'menu',
                  color: AppColors.textAmber,
                  background: AppColors.badgeAmberBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Pendapatan 7 Hari Terakhir',
          ),
          _WeeklyChart(provider: provider),
          const SizedBox(height: 18),
          const SectionHeader(
            icon: Icons.local_fire_department_outlined,
            title: 'Menu Terlaris Hari Ini',
          ),
          _BestSellers(provider: provider),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFBE0C9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 18,
                  color: AppColors.textGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setiap porsi yang diselamatkan hari ini mengurangi '
                    '± ${provider.savedCo2Today.toStringAsFixed(1)} kg jejak CO₂.',
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
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

class _RevenueCard extends StatelessWidget {
  final ShopProvider provider;

  const _RevenueCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final growth = provider.revenueGrowthPercent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD6472D), Color(0xFFA92F1B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Pendapatan Hari Ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  growth == null
                      ? 'Hari ini'
                      : '${growth >= 0 ? '↑' : '↓'} ${growth.abs()}%',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formats.rupiah(provider.revenueToday),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.completedToday.length} pesanan selesai • '
            'kemarin ${Formats.rupiah(provider.revenueYesterday)}',
            style: const TextStyle(fontSize: 9.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color background;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(11),
      radius: 15,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final ShopProvider provider;

  const _WeeklyChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index)),
    );

    final revenues = days.map((day) {
      return provider.orders
          .where((order) {
            if (!order.isSelesai) return false;
            final waktu = order.waktuPengambilan ?? order.tanggalPesan;
            return waktu.year == day.year &&
                waktu.month == day.month &&
                waktu.day == day.day;
          })
          .fold<double>(0, (total, order) => total + order.totalHarga);
    }).toList();

    final maxRevenue = revenues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(days.length, (index) {
            final value = revenues[index];
            final ratio = maxRevenue <= 0 ? 0.0 : value / maxRevenue;
            final isToday = index == days.length - 1;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      value <= 0 ? '-' : Formats.number((value / 1000).round()),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      height: 12 + (82 * ratio),
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: AppColors.primaryGradient,
                              )
                            : null,
                        color: isToday ? null : const Color(0xFFF3D9CB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      Formats.dayName(days[index]).substring(0, 3),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BestSellers extends StatelessWidget {
  final ShopProvider provider;

  const _BestSellers({required this.provider});

  @override
  Widget build(BuildContext context) {
    final quantities = <String, int>{};
    final names = <String, String>{};

    for (final order in provider.completedToday) {
      for (final item in order.items) {
        quantities[item.productId] =
            (quantities[item.productId] ?? 0) + item.jumlah;
        names[item.productId] = item.namaProduk;
      }
    }

    if (quantities.isEmpty) {
      return const EmptyState(
        icon: Icons.local_fire_department_outlined,
        title: 'Belum ada penjualan hari ini',
        message: 'Menu terlaris akan muncul setelah pesanan pertama selesai.',
      );
    }

    final entries = quantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final maxValue = top.first.value;

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(top.length, (index) {
          final entry = top[index];
          final name = names[entry.key] ?? 'Produk';
          final ratio = maxValue <= 0 ? 0.0 : entry.value / maxValue;

          return Padding(
            padding: EdgeInsets.only(bottom: index == top.length - 1 ? 0 : 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppColors.orangeSoft
                        : AppColors.softGrey,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: index == 0
                          ? AppColors.orange
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value} porsi',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: AppColors.softGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            index == 0 ? AppColors.primary : AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
