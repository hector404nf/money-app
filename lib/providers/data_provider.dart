import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/email_parser_template.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class DataProvider extends ChangeNotifier {
  // --- Estado en Memoria (Simulando DB) ---
  final List<Account> _accounts = [];
  final List<Category> _categories = [];
  final List<Transaction> _transactions = [];
  final List<Goal> _goals = [];
  final List<EmailParserTemplate> _emailTemplates = [];
  String? _selectedMonthKey;
  Box<dynamic>? _box;
  final CloudSyncService _cloudSyncService = CloudSyncService();
  bool _isCloudSyncing = false;
  Timer? _cloudAutoUploadTimer;
  bool _cloudAutoUploadPending = false;

  // Getters
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<EmailParserTemplate> get emailTemplates => List.unmodifiable(_emailTemplates);
  String? get selectedMonthKey => _selectedMonthKey;
  bool get isCloudSyncing => _isCloudSyncing;
  bool get isCloudSignedIn => _cloudSyncService.currentUser != null;
  String? get cloudUserEmail => _cloudSyncService.currentUser?.email;

  double getCategorySpending(String categoryId, String? monthKey) {
    if (monthKey == null) return 0.0;
    return _transactions
        .where((t) => 
          t.categoryId == categoryId && 
          t.monthKey == monthKey && 
          t.amount < 0
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  List<String> get availableMonthKeys {
    final keys = _transactions.map((t) => t.monthKey).toSet().toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  void setSelectedMonthKey(String? monthKey) {
    _selectedMonthKey = monthKey;

    DateTime targetDate;
    if (monthKey != null) {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]) ?? DateTime.now().year;
        final month = int.tryParse(parts[1]) ?? DateTime.now().month;
        targetDate = DateTime(year, month, 1);
      } else {
        targetDate = DateTime.now();
      }
    } else {
      targetDate = DateTime.now();
    }

    ensureRecurringTransactionsGenerated(targetDate);
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
  }

  // Constructor: Carga datos iniciales de prueba
  DataProvider() {
    // _loadDummyData(); // Desactivado para producción
    unawaited(_initStorage().catchError((_) {}));
  }

  Future<void> _initStorage() async {
    try {
      _box ??= await Hive.openBox('money_app');
      final storedAccounts = _box!.get('accounts');
      final storedCategories = _box!.get('categories');
      final storedTransactions = _box!.get('transactions');
      final storedGoals = _box!.get('goals');
      final storedEmailTemplates = _box!.get('emailTemplates');
      final storedSelectedMonthKey = _box!.get('selectedMonthKey');

      final hasData = storedAccounts is List &&
          storedCategories is List &&
          storedTransactions is List &&
          storedAccounts.isNotEmpty;

      if (hasData) {
        _accounts
          ..clear()
          ..addAll(
            storedAccounts
                .cast<Map>()
                .map((m) => Account.fromMap(Map<String, dynamic>.from(m)))
                .where((a) => a.id.length > 5), // Filtrar cuentas dummy (ids cortos '1', '2', '3')
          );
        _categories
          ..clear()
          ..addAll(
            storedCategories
                .cast<Map>()
                .map((m) => Category.fromMap(Map<String, dynamic>.from(m)))
                .where((c) => c.id.length > 5), // Filtrar categorías dummy ('c1', etc)
          );
        _transactions
          ..clear()
          ..addAll(
            storedTransactions
                .cast<Map>()
                .map((m) => Transaction.fromMap(Map<String, dynamic>.from(m)))
                .where((t) => t.id.length > 5), // Filtrar transacciones dummy ('t1', 't2')
          );
        
        if (storedGoals is List) {
          _goals
            ..clear()
            ..addAll(
              storedGoals
                  .cast<Map>()
                  .map((m) => Goal.fromMap(Map<String, dynamic>.from(m))),
            );
        }

        if (storedEmailTemplates is List) {
          _emailTemplates
            ..clear()
            ..addAll(
              storedEmailTemplates
                  .cast<Map>()
                  .map((m) => EmailParserTemplate.fromMap(Map<String, dynamic>.from(m))),
            );
        }

        ensureRecurringTransactionsGenerated(DateTime.now());
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _selectedMonthKey = storedSelectedMonthKey as String?;
        notifyListeners();
      } else {
        _addDefaultCategories();
        await _saveToStorage();
      }
    } catch (_) {}
  }

  void _addDefaultCategories() {
    _categories
      ..clear()
      ..addAll([
        Category(
          id: 'cat_income_salary',
          name: 'Salario',
          kind: CategoryKind.income,
        ),
        Category(
          id: 'cat_income_other',
          name: 'Otros ingresos',
          kind: CategoryKind.income,
        ),
        Category(
          id: 'cat_expense_fixed',
          name: 'Gastos fijos',
          kind: CategoryKind.expense,
        ),
        Category(
          id: 'cat_expense_food',
          name: 'Comida',
          kind: CategoryKind.expense,
        ),
        Category(
          id: 'cat_expense_transport',
          name: 'Transporte',
          kind: CategoryKind.expense,
        ),
        Category(
          id: 'cat_expense_entertainment',
          name: 'Entretenimiento',
          kind: CategoryKind.expense,
        ),
        Category(
          id: 'cat_transfer_internal',
          name: 'Transferencia interna',
          kind: CategoryKind.transfer,
          isTransferLike: true,
        ),
      ]);
  }

  void loadDummyForTests() {
    if (_accounts.isNotEmpty || _transactions.isNotEmpty) return;
    _loadDummyData();
  }

  Future<void> _saveToStorage() async {
    if (_box == null) return;
    await _box!.put('accounts', _accounts.map((a) => a.toMap()).toList());
    await _box!.put('categories', _categories.map((c) => c.toMap()).toList());
    await _box!.put('transactions', _transactions.map((t) => t.toMap()).toList());
    await _box!.put('goals', _goals.map((g) => g.toMap()).toList());
    await _box!.put('emailTemplates', _emailTemplates.map((t) => t.toMap()).toList());
    await _box!.put('selectedMonthKey', _selectedMonthKey);
  }

  void _scheduleCloudAutoUpload() {
    if (!isCloudSignedIn) return;
    _cloudAutoUploadPending = true;
    _cloudAutoUploadTimer?.cancel();
    _cloudAutoUploadTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_runCloudAutoUpload());
    });
  }

  Future<void> _runCloudAutoUpload() async {
    if (!_cloudAutoUploadPending) return;
    if (!isCloudSignedIn) {
      _cloudAutoUploadPending = false;
      return;
    }
    if (_isCloudSyncing) {
      _scheduleCloudAutoUpload();
      return;
    }

    _cloudAutoUploadPending = false;
    try {
      await uploadToCloud();
    } catch (_) {
      _cloudAutoUploadPending = true;
      _scheduleCloudAutoUpload();
    }
  }

  Future<void> signInWithGoogle() async {
    _isCloudSyncing = true;
    notifyListeners();
    try {
      await _cloudSyncService.signInWithGoogle();
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  Future<void> signOutCloud() async {
    _isCloudSyncing = true;
    notifyListeners();
    try {
      await _cloudSyncService.signOut();
      _cloudAutoUploadPending = false;
      _cloudAutoUploadTimer?.cancel();
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  Future<void> uploadToCloud() async {
    _isCloudSyncing = true;
    notifyListeners();
    try {
      await _cloudSyncService.uploadAll(
        accounts: accounts,
        categories: categories,
        transactions: transactions,
        selectedMonthKey: _selectedMonthKey,
      );
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cloudAutoUploadTimer?.cancel();
    super.dispose();
  }

  Future<void> downloadFromCloud({bool replaceLocal = true}) async {
    _isCloudSyncing = true;
    notifyListeners();
    try {
      final data = await _cloudSyncService.downloadAll();
      if (replaceLocal) {
        _accounts
          ..clear()
          ..addAll(data.accounts);
        _categories
          ..clear()
          ..addAll(data.categories);
        _transactions
          ..clear()
          ..addAll(data.transactions);
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _selectedMonthKey = data.selectedMonthKey;
        await _saveToStorage();
        notifyListeners();
      }
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  // --- Lógica de Negocio / Cálculos ---

  /// Calcula el saldo actual de una cuenta
  /// Saldo = SaldoInicial + Suma(Movimientos)
  double getAccountBalance(String accountId) {
    // Si es un objetivo que actúa como cuenta
    final goalIndex = _goals.indexWhere((g) => g.id == accountId);
    if (goalIndex != -1) {
      return _goals[goalIndex].currentAmount;
    }

    // Cuenta normal (o virtual si no existe en la lista)
    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: accountId,
        name: 'Cuenta',
        type: AccountType.other,
        initialBalance: 0,
      ),
    );

    double totalMovements = 0;
    for (var tx in _transactions) {
      if (tx.accountId == accountId && tx.status == TransactionStatus.pagado) {
        totalMovements += tx.amount;
      }
    }

    return account.initialBalance + totalMovements;
  }

  /// Calcula Egresos REALES (Excluyendo transferencias y mulas)
  /// Si [monthKey] se provee, filtra por mes.
  double getRealExpenses({String? monthKey}) {
    double total = 0;
    for (var tx in _transactions) {
      if (monthKey != null && tx.monthKey != monthKey) continue;
      if (tx.status != TransactionStatus.pagado) continue;
      if (tx.amount >= 0) continue;
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) continue;
      total += tx.amount;
    }
    return total;
  }

  double getRealExpensesInRange(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    double total = 0;
    for (var tx in _transactions) {
      if (tx.status != TransactionStatus.pagado) continue;
      if (tx.amount >= 0) continue;
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) continue;
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (d.isBefore(startDate) || d.isAfter(endDate)) continue;
      total += tx.amount;
    }
    return total;
  }

  /// Calcula Ingresos totales
  double getIncomes({String? monthKey}) {
    double total = 0;
    for (var tx in _transactions) {
      if (monthKey != null && tx.monthKey != monthKey) continue;
      // Solo transacciones PAGADAS
      if (tx.status != TransactionStatus.pagado) continue;
      
      if (tx.amount > 0) {
        // Opcional: Podríamos excluir también transferencias de entrada si quisiéramos "Ingresos Reales"
        // Pero por defecto el dashboard suele mostrar todo lo que entra.
        // Si es una transferencia interna, entra como + y salió como - en otro lado.
        // Para "Ingresos Reales" (Sueldo), habría que excluir TransferLike también.
        final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
        if (!cat.isTransferLike) {
           total += tx.amount;
        }
      }
    }
    return total;
  }

  Map<String, double> getRealExpensesByCategory({String? monthKey}) {
    final Map<String, double> totals = {};
    for (var tx in _transactions) {
      if (monthKey != null && tx.monthKey != monthKey) continue;
      if (tx.status != TransactionStatus.pagado) continue;
      if (tx.amount >= 0) continue;
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) continue;
      totals[cat.id] = (totals[cat.id] ?? 0) + tx.amount.abs();
    }
    return totals;
  }

  void ensureRecurringTransactionsGenerated(DateTime now) {
    final templates = _transactions.where((t) => t.isRecurring && t.parentRecurringId == null && t.frequency != null).toList();
    if (templates.isEmpty) return;

    final horizon = now.add(const Duration(days: 365));

    for (final template in templates) {
      final chain = _transactions
          .where((t) => t.id == template.id || t.parentRecurringId == template.id)
          .toList();

      if (chain.isEmpty) continue;

      chain.sort((a, b) => a.date.compareTo(b.date));
      var last = chain.last;

      while (true) {
        final nextDate = _addFrequency(last.date, template.frequency!);

        if (!nextDate.isAfter(last.date)) {
          break;
        }

        if (template.recursUntil != null && nextDate.isAfter(template.recursUntil!)) {
          break;
        }

        if (nextDate.isAfter(horizon)) {
          break;
        }

        final monthKey = '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}';

        final newTx = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: nextDate,
          monthKey: monthKey,
          mainType: template.mainType,
          categoryId: template.categoryId,
          accountId: template.accountId,
          amount: template.amount,
          status: TransactionStatus.programado,
          subCategory: template.subCategory,
          dueDate: template.dueDate ?? nextDate,
          notes: template.notes,
          tags: template.tags,
          goalId: template.goalId,
          isRecurring: true,
          frequency: template.frequency,
          recursUntil: template.recursUntil,
          parentRecurringId: template.id,
        );

        _transactions.add(newTx);
        _scheduleNotificationForTransaction(newTx);
        last = newTx;
      }
    }
  }

  DateTime _addFrequency(DateTime date, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return date.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
      case RecurringFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
    }
  }

  // --- Métodos para Programados/Pendientes ---
  
  double getPendingExpenses({String? monthKey}) {
    double total = 0;
    for (var tx in _transactions) {
      if (monthKey != null && tx.monthKey != monthKey) continue;
      if (tx.status == TransactionStatus.pagado) continue; // Solo pendientes/programados
      if (tx.amount >= 0) continue;
      
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) continue;
      
      total += tx.amount;
    }
    return total;
  }
  
  double getPendingIncomes({String? monthKey}) {
    double total = 0;
    for (var tx in _transactions) {
      if (monthKey != null && tx.monthKey != monthKey) continue;
      if (tx.status == TransactionStatus.pagado) continue; // Solo pendientes/programados
      if (tx.amount <= 0) continue;
      
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) continue;
      
      total += tx.amount;
    }
    return total;
  }

  List<Transaction> getPendingTransactions({String? monthKey}) {
    return _transactions.where((tx) {
      if (monthKey != null && tx.monthKey != monthKey) return false;
      if (tx.status == TransactionStatus.pagado) return false;
      
      final cat = _categories.firstWhere((c) => c.id == tx.categoryId);
      if (cat.isTransferLike) return false;
      
      return true;
    }).toList();
  }

  // --- Mutaciones ---

  void addTransaction({
    required double amount,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String? notes,
    String? subCategory,
    required MainType mainType,
    TransactionStatus status = TransactionStatus.pagado,
    DateTime? dueDate,
    String? goalId,
    bool isRecurring = false,
    RecurringFrequency? frequency,
    DateTime? recursUntil,
    String? parentRecurringId,
  }) {
    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID simple temporal
      date: date,
      monthKey: '${date.year}-${date.month.toString().padLeft(2, '0')}',
      mainType: mainType,
      categoryId: categoryId,
      accountId: accountId,
      amount: amount,
      status: status,
      dueDate: dueDate,
      notes: notes,
      subCategory: subCategory,
      goalId: goalId,
      isRecurring: isRecurring,
      frequency: frequency,
      recursUntil: recursUntil,
      parentRecurringId: parentRecurringId,
    );

    _transactions.add(newTx);
    
    // Schedule Notification
    _scheduleNotificationForTransaction(newTx);
    
    // Update goal if applicable (Legacy logic)
    if (goalId != null && status == TransactionStatus.pagado) {
      updateGoalContribution(goalId, amount.abs());
    }
    
    // Update goal if it's acting as an account (New logic)
    // Note: We avoid double counting if goalId passed IS the accountId (unlikely but possible)
    if (accountId != goalId && _goals.any((g) => g.id == accountId) && status == TransactionStatus.pagado) {
       updateGoalContribution(accountId, amount);
    }
    
    ensureRecurringTransactionsGenerated(date);

    _transactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
  }

  void addTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? notes,
    String? goalId,
  }) {
    if (fromAccountId == toAccountId) {
      throw Exception('La cuenta origen y destino no pueden ser la misma');
    }
    final normalizedAmount = amount.abs();
    if (normalizedAmount == 0) {
      throw Exception('El monto debe ser mayor a 0');
    }

    Category transferCategory;
    try {
      transferCategory = _categories.firstWhere((c) => c.isTransferLike);
    } catch (_) {
      transferCategory = Category(
        id: 'cat_transfer_internal',
        name: 'Transferencia interna',
        kind: CategoryKind.transfer,
        isTransferLike: true,
      );
      _categories.add(transferCategory);
      unawaited(_saveToStorage());
    }
    final transferCategoryId = transferCategory.id;
    final baseId = DateTime.now().millisecondsSinceEpoch.toString();
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

    final outTx = Transaction(
      id: '${baseId}_out',
      date: date,
      monthKey: monthKey,
      mainType: MainType.expenses,
      categoryId: transferCategoryId,
      accountId: fromAccountId,
      amount: -normalizedAmount,
      status: TransactionStatus.pagado,
      notes: notes,
    );

    final inTx = Transaction(
      id: '${baseId}_in',
      date: date,
      monthKey: monthKey,
      mainType: MainType.incomes,
      categoryId: transferCategoryId,
      accountId: toAccountId,
      amount: normalizedAmount,
      status: TransactionStatus.pagado,
      notes: notes,
      goalId: goalId,
    );

    _transactions.addAll([outTx, inTx]);
    
    // Update goal if applicable
    if (goalId != null) {
      updateGoalContribution(goalId, normalizedAmount);
    }

    // Update goal if it's acting as an account (New logic)
    // Check if fromAccountId is a goal (money leaving goal)
    if (fromAccountId != goalId && _goals.any((g) => g.id == fromAccountId)) {
       updateGoalContribution(fromAccountId, -normalizedAmount);
    }
    
    // Check if toAccountId is a goal (money entering goal)
    if (toAccountId != goalId && _goals.any((g) => g.id == toAccountId)) {
       updateGoalContribution(toAccountId, normalizedAmount);
    }

    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
  }

  String addCategory({
    required String name,
    required CategoryKind kind,
    String? iconName,
    double? monthlyBudget,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('El nombre no puede estar vacío');
    }

    final alreadyExists = _categories.any(
      (c) => c.kind == kind && c.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyExists) {
      throw Exception('Ya existe una categoría con ese nombre');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newCategory = Category(
      id: id,
      name: trimmedName,
      iconName: iconName,
      kind: kind,
      isTransferLike: kind == CategoryKind.transfer,
      isDebtLike: kind == CategoryKind.debt,
      monthlyBudget: monthlyBudget,
    );

    _categories.add(newCategory);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
    return id;
  }

  void editCategory({
    required String id,
    required String name,
    String? iconName,
    double? monthlyBudget,
  }) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _categories[index];
      _categories[index] = Category(
        id: old.id,
        name: name.trim(),
        iconName: iconName ?? old.iconName,
        kind: old.kind,
        isTransferLike: old.isTransferLike,
        isMoneyLike: old.isMoneyLike,
        isDebtLike: old.isDebtLike,
        monthlyBudget: monthlyBudget,
      );
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
      _scheduleCloudAutoUpload();
    }
  }

  void deleteCategory(String id) {
    // Optional: Check if used in transactions
    final isUsed = _transactions.any((t) => t.categoryId == id);
    if (isUsed) {
      throw Exception('No se puede eliminar una categoría que tiene transacciones asociadas');
    }

    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
  }

  void addAccount({
    required String name,
    required double initialBalance,
    required AccountType type,
  }) {
    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      initialBalance: initialBalance,
      type: type,
    );
    _accounts.add(newAccount);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
  }

  void editAccount({
    required String id,
    String? name,
    double? initialBalance,
    AccountType? type,
  }) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = _accounts[index];
      _accounts[index] = Account(
        id: old.id,
        name: name ?? old.name,
        initialBalance: initialBalance ?? old.initialBalance,
        type: type ?? old.type,
        isActive: old.isActive,
      );
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
    }
  }

  void updateTransactionStatus(String id, TransactionStatus status) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _transactions[index];
      
      // Handle goal update if status changes
      final wasPaid = old.status == TransactionStatus.pagado;
      final isPaid = status == TransactionStatus.pagado;

      if (old.goalId != null) {
        if (!wasPaid && isPaid) {
          updateGoalContribution(old.goalId!, old.amount.abs());
        } else if (wasPaid && !isPaid) {
          updateGoalContribution(old.goalId!, -old.amount.abs());
        }
      }

      // Handle goal update if it's acting as an account
      if (old.accountId != old.goalId && _goals.any((g) => g.id == old.accountId)) {
        if (!wasPaid && isPaid) {
          updateGoalContribution(old.accountId, old.amount);
        } else if (wasPaid && !isPaid) {
          updateGoalContribution(old.accountId, -old.amount);
        }
      }

      _transactions[index] = Transaction(
        id: old.id,
        date: old.date,
        monthKey: old.monthKey,
        mainType: old.mainType,
        categoryId: old.categoryId,
        accountId: old.accountId,
        amount: old.amount,
        status: status,
        dueDate: old.dueDate,
        notes: old.notes,
        subCategory: old.subCategory,
        tags: old.tags,
        goalId: old.goalId,
      );
      
      // Update Notification
      if (status == TransactionStatus.pagado) {
        _cancelNotificationForTransaction(old);
      } else {
        _scheduleNotificationForTransaction(_transactions[index]);
      }

      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
      _scheduleCloudAutoUpload();
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tx = _transactions[index];
      
      // Revert goal contribution if needed
      if (tx.goalId != null && tx.status == TransactionStatus.pagado) {
        updateGoalContribution(tx.goalId!, -tx.amount.abs());
      }
      
      // Revert goal contribution if it was acting as account
      if (tx.accountId != tx.goalId && _goals.any((g) => g.id == tx.accountId) && tx.status == TransactionStatus.pagado) {
         updateGoalContribution(tx.accountId, -tx.amount);
      }

      _cancelNotificationForTransaction(tx);
      _transactions.removeAt(index);
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
      _scheduleCloudAutoUpload();
    }
  }

  // --- Metas (Goals) ---

  void addGoal({
    required String name,
    required double targetAmount,
    DateTime? deadline,
    required int colorValue,
    required String iconName,
  }) {
    final newGoal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      colorValue: colorValue,
      iconName: iconName,
    );
    _goals.add(newGoal);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
  }

  void updateGoalContribution(String id, double amount) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final old = _goals[index];
      _goals[index] = old.copyWith(
        currentAmount: old.currentAmount + amount,
      );
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
      _scheduleCloudAutoUpload();
    }
  }

  void editGoal({
    required String id,
    required String name,
    required double targetAmount,
    DateTime? deadline,
    required int colorValue,
    required String iconName,
  }) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final old = _goals[index];
      _goals[index] = old.copyWith(
        name: name,
        targetAmount: targetAmount,
        deadline: deadline,
        colorValue: colorValue,
        iconName: iconName,
      );
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
      _scheduleCloudAutoUpload();
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
    _scheduleCloudAutoUpload();
  }

  // --- Helpers Notificaciones ---

  void _scheduleNotificationForTransaction(Transaction tx) {
    if (tx.dueDate != null && tx.status != TransactionStatus.pagado) {
      NotificationService().schedulePaymentReminder(
        id: tx.id.hashCode,
        title: 'Recordatorio de Pago',
        body: 'Vencimiento pendiente: ${AppColors.formatCurrency(tx.amount.abs())}',
        scheduledDate: tx.dueDate!,
      );
    }
  }

  void _cancelNotificationForTransaction(Transaction tx) {
    NotificationService().cancelNotification(tx.id.hashCode);
  }

  // --- Email Templates ---
  void addEmailTemplate(EmailParserTemplate template) {
    _emailTemplates.add(template);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
  }

  void updateEmailTemplate(EmailParserTemplate template) {
    final index = _emailTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _emailTemplates[index] = template;
      notifyListeners();
      unawaited(_saveToStorage().catchError((_) {}));
    }
  }

  void deleteEmailTemplate(String id) {
    _emailTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
    unawaited(_saveToStorage().catchError((_) {}));
  }

  // --- Datos Dummy (Fase 2) ---
  void _loadDummyData() {
    // 1. Cuentas
    _accounts.addAll([
      const Account(id: '1', name: 'ITAU', type: AccountType.bank, initialBalance: 5000000),
      const Account(id: '2', name: 'UENO', type: AccountType.bank, initialBalance: 1000000),
      const Account(id: '3', name: 'Efectivo', type: AccountType.cash, initialBalance: 300000),
    ]);

    // 2. Categorías
    _categories.addAll([
      Category(id: 'c1', name: 'Sueldo', kind: CategoryKind.income),
      Category(id: 'c2', name: 'Comida', kind: CategoryKind.expense),
      Category(id: 'c3', name: 'Supermercado', kind: CategoryKind.expense),
      Category(id: 'c4', name: 'Transferencia', kind: CategoryKind.transfer, isTransferLike: true),
    ]);

    // 3. Movimientos
    // Mes actual simulado: 2026-01
    _transactions.addAll([
      // Ingreso de sueldo en ITAU
      Transaction(
        id: 't1',
        date: DateTime(2026, 1, 5),
        monthKey: '2026-01',
        mainType: MainType.incomes,
        categoryId: 'c1',
        accountId: '1', // ITAU
        amount: 15000000,
        status: TransactionStatus.pagado,
      ),
      // Gasto Supermercado en ITAU
      Transaction(
        id: 't2',
        date: DateTime(2026, 1, 10),
        monthKey: '2026-01',
        mainType: MainType.expenses,
        categoryId: 'c3',
        accountId: '1', // ITAU
        amount: -800000,
        status: TransactionStatus.pagado,
        subCategory: 'Casa Rica',
      ),
      // Transferencia de ITAU a UENO (Salida)
      Transaction(
        id: 't3',
        date: DateTime(2026, 1, 15),
        monthKey: '2026-01',
        mainType: MainType.expenses,
        categoryId: 'c4', // Transferencia
        accountId: '1', // ITAU
        amount: -2000000,
        status: TransactionStatus.pagado,
        notes: 'Envío a Ueno',
      ),
      // Transferencia de ITAU a UENO (Entrada)
      Transaction(
        id: 't4',
        date: DateTime(2026, 1, 15),
        monthKey: '2026-01',
        mainType: MainType.incomes,
        categoryId: 'c4', // Transferencia
        accountId: '2', // UENO
        amount: 2000000,
        status: TransactionStatus.pagado,
        notes: 'Recibido de Itau',
      ),
    ]);
    
    // 4. Metas
    if (_goals.isEmpty) {
      _goals.addAll([
        Goal(
          id: 'g1',
          name: 'Auto Nuevo',
          targetAmount: 150000000,
          currentAmount: 25000000,
          deadline: DateTime(2027, 12, 31),
          colorValue: Colors.blue.value,
          iconName: 'directions_car',
        ),
        Goal(
          id: 'g2',
          name: 'Vacaciones',
          targetAmount: 10000000,
          currentAmount: 2000000,
          deadline: DateTime(2026, 6, 1),
          colorValue: Colors.orange.value,
          iconName: 'flight',
        ),
      ]);
    }
    
    notifyListeners();
  }
}
