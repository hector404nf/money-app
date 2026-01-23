import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/calendar_view.dart';
import '../widgets/prediction_card.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'transaction_details_screen.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionStatus? _filterStatus;
  DateTimeRange? _filterDateRange;
  bool _isCalendarView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'HOY';
    if (checkDate == yesterday) return 'AYER';
    
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${date.day} ${months[date.month - 1]}".toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final selectedMonthKey = provider.selectedMonthKey;
    
    // 1. Start with all transactions
    var filteredTransactions = provider.transactions;

    // 2. Apply filters (Status, Date Range, Search) - EXCEPT Month
    // Filter by Status
    if (_filterStatus != null) {
      filteredTransactions = filteredTransactions.where((t) => t.status == _filterStatus).toList();
    }

    // Filter by Date Range
    if (_filterDateRange != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredTransactions = filteredTransactions.where((t) {
        final category = provider.categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => Category(id: '', name: '', kind: CategoryKind.expense),
        );
        final categoryName = category.name.toLowerCase();
        final note = t.notes?.toLowerCase() ?? '';
        final amount = t.amount.abs().toString();
        
        return note.contains(query) || categoryName.contains(query) || amount.contains(query);
      }).toList();
    }

    // 3. Prepare transactions for List View (Apply Month Filter)
    var listTransactions = selectedMonthKey == null
        ? filteredTransactions
        : filteredTransactions.where((t) => t.monthKey == selectedMonthKey).toList();

    // 4. Determine focused day for Calendar
    DateTime? initialFocusedDay;
    if (selectedMonthKey != null) {
       try {
         // Find any transaction in the selected month to get the year/month
         // We search in provider.transactions to ensure we find the month even if filters hide all txs
         final tx = provider.transactions.firstWhere((t) => t.monthKey == selectedMonthKey);
         initialFocusedDay = tx.date;
       } catch (_) {
         // If no transaction found for that key (shouldn't happen if key exists), default to now
       }
    }

    // Group by date for List View
    final Map<String, List<dynamic>> grouped = {};
    for (var tx in listTransactions) {
      final dateKey = _formatDateKey(tx.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Movimientos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isCalendarView ? Icons.list : Icons.calendar_month,
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.secondary : AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCalendarView = !_isCalendarView;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedMonthKey,
                          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).brightness == Brightness.dark ? AppColors.secondary : AppColors.primary),
                          dropdownColor: Theme.of(context).cardTheme.color,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.secondary : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ),
                            ...provider.availableMonthKeys.map(
                              (key) => DropdownMenuItem<String?>(
                                value: key,
                                child: Text(key, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                              ),
                            ),
                          ],
                          onChanged: (value) => provider.setSelectedMonthKey(value),
                        ),
                      ),
                    ),
                  ],
                ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).cardTheme.color,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _showFilterModal(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_filterStatus != null || _filterDateRange != null)
                              ? AppColors.primary
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: (_filterStatus != null || _filterDateRange != null)
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Prediction Card (IA)
          if (!_isCalendarView &&
              _searchQuery.isEmpty &&
              _filterStatus == null &&
              _filterDateRange == null &&
              (selectedMonthKey == null || 
               selectedMonthKey == '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'))
            PredictionCard(
              transactions: provider.transactions,
              currentBalance: provider.calculateTotalBalance(),
            ),

          Expanded(
            child: _isCalendarView
                ? CalendarView(
                    transactions: filteredTransactions,
                    initialFocusedDay: initialFocusedDay,
                  )
                : listTransactions.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final dayTx = grouped[dateKey]!;
                      final date = dayTx.first.date as DateTime; 
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(
                              _formatDateLabel(date),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          ...dayTx.map((tx) => _buildTransactionTile(context, tx, provider)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar Movimientos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Filter
                  Text('Estado', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Todos',
                          isSelected: _filterStatus == null,
                          onSelected: () => setModalState(() => _filterStatus = null),
                        ),
                        const SizedBox(width: 8),
                        ...TransactionStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: status.name.toUpperCase(),
                              isSelected: _filterStatus == status,
                              onSelected: () => setModalState(() => _filterStatus = status),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Range Filter
                  Text('Rango de Fechas', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Todos',
                        isSelected: _filterDateRange == null,
                        onSelected: () => setModalState(() => _filterDateRange = null),
                      ),
                      _buildFilterChip(
                        label: 'Este Mes',
                        isSelected: _isCurrentMonth(),
                        onSelected: () {
                          final now = DateTime.now();
                          final start = DateTime(now.year, now.month, 1);
                          final end = DateTime(now.year, now.month + 1, 0);
                          setModalState(() => _filterDateRange = DateTimeRange(start: start, end: end));
                        },
                      ),
                      ActionChip(
                        label: const Text('Personalizado'),
                        backgroundColor: _isCustomDate() 
                            ? AppColors.primary.withOpacity(0.1) 
                            : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardTheme.color : Colors.grey[100]),
                        labelStyle: TextStyle(
                          color: _isCustomDate() 
                              ? AppColors.primary 
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          fontWeight: FontWeight.w600,
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: _filterDateRange,
                          );
                          if (picked != null) {
                            setModalState(() => _filterDateRange = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Apply filters
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: isDark ? Theme.of(context).cardTheme.color : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      side: isSelected ? const BorderSide(color: AppColors.primary) : null,
    );
  }

  bool _isCurrentMonth() {
    if (_filterDateRange == null) return false;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return _filterDateRange!.start.isAtSameMomentAs(start) && 
           _filterDateRange!.end.year == end.year && 
           _filterDateRange!.end.month == end.month && 
           _filterDateRange!.end.day == end.day;
  }

  bool _isCustomDate() {
    return _filterDateRange != null && !_isCurrentMonth();
  }

  Widget _buildTransactionTile(BuildContext context, dynamic txDynamic, DataProvider provider) {
      final Transaction tx = txDynamic;
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

      final tile = TransactionTile(
        categoryName: category.name,
        iconName: category.iconName,
        note: tx.notes ?? tx.subCategory,
        amount: tx.amount,
        color: color,
        status: tx.status,
        dueDate: tx.dueDate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailsScreen(transaction: tx),
          ),
        ),
      );

      if (tx.status == TransactionStatus.pagado) {
        return tile;
      }

      return Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.startToEnd,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Marcar como Pagado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        onDismissed: (direction) {
          provider.updateTransactionStatus(tx.id, TransactionStatus.pagado);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marcado como pagado')),
          );
        },
        child: tile,
      );
  }


  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay movimientos',
            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
