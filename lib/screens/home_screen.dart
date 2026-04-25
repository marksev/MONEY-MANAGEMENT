import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabIndex == 0 ? const _DashboardView() : const CategoriesScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = provider.filteredExpenses;
        final total = provider.totalFiltered;
        final categoryTotals = provider.categoryTotals;
        final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

        return CustomScrollView(
          slivers: [
            // ── Header with total + filter tabs ─────────────────────────────
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          _periodLabel(provider.filter),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FilterTabs(provider: provider),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Category breakdown ───────────────────────────────────────────
            if (categoryTotals.isNotEmpty) ...[
              _sectionHeader(context, 'By Category'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _CategoryTile(
                      category: categoryTotals[i].key,
                      amount: categoryTotals[i].value,
                      percent: total > 0 ? categoryTotals[i].value / total : 0,
                    ),
                    childCount: categoryTotals.length,
                  ),
                ),
              ),
            ],

            // ── Recent expenses ──────────────────────────────────────────────
            _sectionHeader(context, 'Expenses'),
            if (filtered.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ExpenseTile(
                    expense: filtered[i],
                    category: provider.getCategoryById(filtered[i].categoryId),
                    provider: provider,
                  ),
                  childCount: filtered.length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
          ],
        );
      },
    );
  }

  SliverPadding _sectionHeader(BuildContext context, String title) =>
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );

  String _periodLabel(FilterPeriod f) {
    switch (f) {
      case FilterPeriod.today:
        return 'Spent Today';
      case FilterPeriod.week:
        return 'Spent This Week';
      case FilterPeriod.month:
        return 'Spent This Month';
      case FilterPeriod.year:
        return 'Spent This Year';
    }
  }
}

// ─── Filter tabs ─────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final AppProvider provider;
  const _FilterTabs({required this.provider});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (FilterPeriod.today, 'Today'),
      (FilterPeriod.week, 'Week'),
      (FilterPeriod.month, 'Month'),
      (FilterPeriod.year, 'Year'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tabs.map((t) {
        final selected = provider.filter == t.$1;
        return GestureDetector(
          onTap: () => provider.setFilter(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.$2,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Category breakdown tile ──────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Category category;
  final double amount;
  final double percent;

  const _CategoryTile({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _EmojiAvatar(emoji: category.emoji, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${(percent * 100).toStringAsFixed(1)}% of total',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Expense list tile ────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final AppProvider provider;

  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final color = category != null ? Color(category!.color) : Colors.grey;
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final label = expense.description.isNotEmpty
        ? expense.description
        : (category?.name ?? 'Expense');

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red.shade400,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => provider.deleteExpense(expense.id!),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddExpenseScreen(expense: expense)),
        ),
        leading: _EmojiAvatar(
          emoji: category?.emoji ?? '💰',
          color: color,
          size: 44,
          radius: 12,
          fontSize: 22,
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(expense.date),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Text(
          currency.format(expense.amount),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final double radius;
  final double fontSize;

  const _EmojiAvatar({
    required this.emoji,
    required this.color,
    this.size = 40,
    this.radius = 10,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
          child: Text(emoji, style: TextStyle(fontSize: fontSize))),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No expenses yet',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Tap + Add Expense to get started',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}
