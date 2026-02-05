import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/data_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';
import 'add_transaction_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DataProvider>(context);
    
    // Filter for active recurring transaction templates (Subscriptions)
    // We assume subscriptions are Expenses.
    final subscriptions = provider.transactions.where((t) {
      return t.isRecurring && 
             t.parentRecurringId == null && 
             t.frequency != null &&
             t.amount < 0; // Only expenses
    }).toList();

    // Sort by amount (descending)
    subscriptions.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));

    // Calculate total monthly cost
    double totalMonthly = 0;
    for (var sub in subscriptions) {
      double monthlyAmount = sub.amount.abs();
      switch (sub.frequency) {
        case RecurringFrequency.daily:
          monthlyAmount *= 30;
          break;
        case RecurringFrequency.weekly:
          monthlyAmount *= 4.33;
          break;
        case RecurringFrequency.monthly:
          monthlyAmount *= 1;
          break;
        case RecurringFrequency.yearly:
          monthlyAmount /= 12;
          break;
        default:
          break;
      }
      totalMonthly += monthlyAmount;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Suscripciones'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: theme.iconTheme.color),
          bottom: TabBar(
            labelColor: theme.textTheme.titleMedium?.color,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorColor: Colors.purple,
            tabs: const [
              Tab(text: 'Lista', icon: Icon(Icons.list)),
              Tab(text: 'Calendario', icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: List View
            Column(
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [Colors.purple.shade900, Colors.deepPurple.shade900]
                          : [Colors.purple.shade100, Colors.deepPurple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Costo Mensual Estimado',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.purple.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₲ ${totalMonthly.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.purple.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${subscriptions.length} suscripciones activas',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white60 : Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: subscriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.repeat, size: 64, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes suscripciones activas',
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: subscriptions.length,
                          itemBuilder: (context, index) {
                            final sub = subscriptions[index];
                            final category = provider.categories.firstWhere(
                              (c) => c.id == sub.categoryId,
                              orElse: () => Category(id: 'unknown', name: 'Otros', kind: CategoryKind.expense),
                            );

                            final color = AppColors.expense;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: theme.cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconHelper.getIconByName(category.iconName ?? 'category'),
                                    color: color,
                                  ),
                                ),
                                title: Text(
                                  (sub.notes?.isNotEmpty == true) ? sub.notes! : category.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${_getFrequencyText(sub.frequency)} • Próx: ${_formatDate(sub.dueDate ?? sub.date)}',
                                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                                ),
                                trailing: Text(
                                  '₲ ${sub.amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.expense,
                                  ),
                                ),
                                onTap: () {
                                   Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionScreen(transactionToEdit: sub),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // Tab 2: Calendar View
            _buildCalendarView(context, provider, subscriptions, isDark),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(isRecurringConfig: true),
              ),
            );
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, DataProvider provider, List<Transaction> subscriptions, bool isDark) {
    final theme = Theme.of(context);
    
    // Get events for selected day
    final eventsForDay = _getEventsForDay(_selectedDay ?? DateTime.now(), subscriptions);

    return Column(
      children: [
        TableCalendar<Transaction>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
             setState(() {
               _calendarFormat = format;
             });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getEventsForDay(day, subscriptions),
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            weekendTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            outsideTextStyle: TextStyle(color: theme.disabledColor),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!,
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.iconTheme.color),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventsForDay.length,
            itemBuilder: (context, index) {
              final sub = eventsForDay[index];
              final category = provider.categories.firstWhere(
                (c) => c.id == sub.categoryId,
                orElse: () => Category(id: 'unknown', name: 'Otros', kind: CategoryKind.expense),
              );
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: theme.cardTheme.color,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIconByName(category.iconName ?? 'category'),
                      color: AppColors.expense,
                    ),
                  ),
                  title: Text(
                    (sub.notes?.isNotEmpty == true) ? sub.notes! : category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Vence hoy'),
                  trailing: Text(
                    '₲ ${sub.amount.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Transaction> _getEventsForDay(DateTime day, List<Transaction> subscriptions) {
    return subscriptions.where((sub) {
      final start = sub.dueDate ?? sub.date;
      
      // Basic logic for recurrence check
      switch (sub.frequency) {
        case RecurringFrequency.daily:
          return true;
        case RecurringFrequency.weekly:
          return day.weekday == start.weekday;
        case RecurringFrequency.monthly:
          int dueDay = start.day;
          int lastDayOfCurrentMonth = DateTime(day.year, day.month + 1, 0).day;
          
          if (dueDay > lastDayOfCurrentMonth) {
            // Handle month end overflow (e.g. due 31st, current month has 30 or 28 days)
            return day.day == lastDayOfCurrentMonth;
          }
          return day.day == dueDay;
        case RecurringFrequency.yearly:
          return day.month == start.month && day.day == start.day;
        default:
          return false;
      }
    }).toList();
  }

  String _getFrequencyText(RecurringFrequency? freq) {
    switch (freq) {
      case RecurringFrequency.daily: return 'Diario';
      case RecurringFrequency.weekly: return 'Semanal';
      case RecurringFrequency.monthly: return 'Mensual';
      case RecurringFrequency.yearly: return 'Anual';
      default: return 'Recurrente';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
