import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../screens/transaction_details_screen.dart';
import 'transaction_tile.dart';

class CalendarView extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime? initialFocusedDay;
  
  const CalendarView({
    super.key, 
    required this.transactions,
    this.initialFocusedDay,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
    _selectedDay = _focusedDay;
  }

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocusedDay != null && widget.initialFocusedDay != oldWidget.initialFocusedDay) {
      setState(() {
        _focusedDay = widget.initialFocusedDay!;
        _selectedDay = _focusedDay;
      });
    }
  }

  List<Transaction> _getTransactionsForDay(DateTime day, List<Transaction> allTransactions) {
    return allTransactions.where((tx) {
      return isSameDay(tx.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Unused

    final transactions = widget.transactions;

    return Column(
      children: [
        TableCalendar<Transaction>(
          locale: 'es_ES',
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            return _getTransactionsForDay(day, transactions);
          },
          calendarStyle: CalendarStyle(
            // Use decoration for markers
            markerSize: 8,
            markersMaxCount: 1,
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            // Use prioritized builders to show background colors
            defaultBuilder: (context, day, focusedDay) => _buildDayCell(context, day, false, false),
            todayBuilder: (context, day, focusedDay) => _buildDayCell(context, day, true, false),
            selectedBuilder: (context, day, focusedDay) => _buildDayCell(context, day, false, true),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedDay == null 
              ? const Center(child: Text('Selecciona un día'))
              : _buildTransactionList(_getTransactionsForDay(_selectedDay!, transactions), provider),
        ),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, bool isToday, bool isSelected) {
    final transactions = _getTransactionsForDay(day, widget.transactions);
    
    // Calculate net total and check for expenses
    double netTotal = 0;
    bool hasExpenses = false;
    for (var tx in transactions) {
      netTotal += tx.amount;
      if (tx.amount < 0) hasExpenses = true;
    }

    // Determine background color
    Color? bgColor;
    Color? textColor; // Null lets it inherit from Theme
    BoxDecoration? decoration;

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      bgColor = AppColors.primary.withOpacity(0.3);
      decoration = BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      );
    } else {
      // Past or Present days logic
      // Note: "Clean" days logic should probably only apply to past days, 
      // otherwise the whole future month is green.
      // But user might want to see scheduled transactions in future? 
      // Let's keep it simple: Color based on transactions for any day that has them.
      // For "Clean" (no transactions), only color past days.
      
      final now = DateTime.now();
      final isPastOrToday = day.year < now.year || 
                           (day.year == now.year && day.month < now.month) ||
                           (day.year == now.year && day.month == now.month && day.day <= now.day);

      if (hasExpenses && netTotal < 0) {
          // "Días con muchos gastos en rojo" -> Net negative
          bgColor = AppColors.expense.withOpacity(0.2);
      } else if (hasExpenses && netTotal >= 0) {
          // Has expenses but income covers it -> Green
          bgColor = AppColors.income.withOpacity(0.2);
      } else if (!hasExpenses && isPastOrToday) {
          // "Días limpios en verde" -> No expenses (Clean) - Only for past/today
          bgColor = AppColors.income.withOpacity(0.2);
      } else if (!hasExpenses && !isPastOrToday) {
         // Future clean days -> No color
         bgColor = null;
      }
      
      if (bgColor != null) {
        decoration = BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        );
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor, // Inherits if null
            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> dayTransactions, DataProvider provider) {
    if (dayTransactions.isEmpty) {
      return Center(
        child: Text(
          'Sin movimientos',
          style: TextStyle(
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: dayTransactions.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final tx = dayTransactions[index];
        final category = provider.categories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => Category(id: 'unknown', name: 'Desconocido', kind: CategoryKind.expense),
        );
        final isTransfer = category.isTransferLike;
        final isExpense = !isTransfer && tx.amount < 0;
        final Color color = isTransfer
            ? AppColors.transfer
            : isExpense
                ? AppColors.expense
                : AppColors.income;

        return TransactionTile(
          categoryName: category.name,
          iconName: category.iconName,
          note: tx.notes ?? tx.subCategory,
          amount: tx.amount,
          color: color,
          status: tx.status,
          dueDate: tx.dueDate,
          onTap: () {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailsScreen(transaction: tx),
              ),
            );
          },
        );
      },
    );
  }
}
