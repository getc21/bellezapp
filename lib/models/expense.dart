class Expense {
  final String id;
  final String storeId;
  final double amount;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final DateTime date;
  final String type; // 'expense', 'income'

  Expense({
    required this.id,
    required this.storeId,
    required this.amount,
    this.description,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    required this.date,
    this.type = 'expense',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final categoryIdValue = json['categoryId'];
    String? categoryId;
    String? categoryName;
    String? categoryIcon;
    
    if (categoryIdValue is Map) {
      categoryId = categoryIdValue['_id'] as String?;
      categoryName = categoryIdValue['name'] as String?;
      categoryIcon = categoryIdValue['icon'] as String?;
    } else if (categoryIdValue is String) {
      categoryId = categoryIdValue;
    }
    
    return Expense(
      id: json['_id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      type: json['type'] as String? ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'storeId': storeId,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}

class ExpenseCategory {
  final String id;
  final String storeId;
  final String name;
  final String? icon;
  final DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.storeId,
    required this.name,
    this.icon,
    required this.createdAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['_id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin categoría',
      icon: json['icon'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'storeId': storeId,
      'name': name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ExpenseReport {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double totalExpense;
  final int expenseCount;
  final List<ExpenseCategoryReport> byCategory;
  final List<Expense> topExpenses;
  final double averageExpense;

  ExpenseReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalExpense,
    required this.expenseCount,
    required this.byCategory,
    required this.topExpenses,
    required this.averageExpense,
  });

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    final startDateStr = json['startDate'];
    final endDateStr = json['endDate'];
    
    return ExpenseReport(
      period: json['period'] as String? ?? 'monthly',
      startDate: startDateStr != null ? DateTime.parse(startDateStr.toString()) : DateTime.now().subtract(Duration(days: 30)),
      endDate: endDateStr != null ? DateTime.parse(endDateStr.toString()) : DateTime.now(),
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      expenseCount: json['expenseCount'] as int? ?? 0,
      byCategory: json['byCategory'] is List
          ? (json['byCategory'] as List)
              .map((e) => ExpenseCategoryReport.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      topExpenses: json['topExpenses'] is List
          ? (json['topExpenses'] as List)
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      averageExpense: (json['averageExpense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseCategoryReport {
  final String name;
  final String? icon;
  final double total;
  final int count;
  final List<Expense> items;

  ExpenseCategoryReport({
    required this.name,
    this.icon,
    required this.total,
    required this.count,
    required this.items,
  });

  factory ExpenseCategoryReport.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryReport(
      name: json['name'] as String? ?? 'Sin categoría',
      icon: json['icon'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
      items: json['items'] is List
          ? (json['items'] as List)
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

// 📊 COMPARACIÓN DE PERÍODOS DE GASTOS
class ExpensePeriodComparison {
  final DateTime periodOneStart;
  final DateTime periodOneEnd;
  final DateTime periodTwoStart;
  final DateTime periodTwoEnd;
  final double totalExpensePeriodOne;
  final double totalExpensePeriodTwo;
  final double difference;
  final double percentageChange;
  final int countPeriodOne;
  final int countPeriodTwo;
  final double averagePeriodOne;
  final double averagePeriodTwo;
  final List<CategoryComparison> byCategory;

  ExpensePeriodComparison({
    required this.periodOneStart,
    required this.periodOneEnd,
    required this.periodTwoStart,
    required this.periodTwoEnd,
    required this.totalExpensePeriodOne,
    required this.totalExpensePeriodTwo,
    required this.difference,
    required this.percentageChange,
    required this.countPeriodOne,
    required this.countPeriodTwo,
    required this.averagePeriodOne,
    required this.averagePeriodTwo,
    required this.byCategory,
  });

  factory ExpensePeriodComparison.fromJson(Map<String, dynamic> json) {
    final p1Start = json['periodOne']?['startDate'];
    final p1End = json['periodOne']?['endDate'];
    final p2Start = json['periodTwo']?['startDate'];
    final p2End = json['periodTwo']?['endDate'];

    return ExpensePeriodComparison(
      periodOneStart: p1Start != null ? DateTime.parse(p1Start.toString()) : DateTime.now(),
      periodOneEnd: p1End != null ? DateTime.parse(p1End.toString()) : DateTime.now(),
      periodTwoStart: p2Start != null ? DateTime.parse(p2Start.toString()) : DateTime.now(),
      periodTwoEnd: p2End != null ? DateTime.parse(p2End.toString()) : DateTime.now(),
      totalExpensePeriodOne: (json['periodOne']?['totalExpense'] as num?)?.toDouble() ?? 0.0,
      totalExpensePeriodTwo: (json['periodTwo']?['totalExpense'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
      countPeriodOne: json['periodOne']?['expenseCount'] as int? ?? 0,
      countPeriodTwo: json['periodTwo']?['expenseCount'] as int? ?? 0,
      averagePeriodOne: (json['periodOne']?['averageExpense'] as num?)?.toDouble() ?? 0.0,
      averagePeriodTwo: (json['periodTwo']?['averageExpense'] as num?)?.toDouble() ?? 0.0,
      byCategory: json['byCategory'] is List
          ? (json['byCategory'] as List)
              .map((e) => CategoryComparison.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

// 📊 COMPARACIÓN DE CATEGORÍA
class CategoryComparison {
  final String name;
  final String? icon;
  final double amountPeriodOne;
  final double amountPeriodTwo;
  final double difference;
  final double percentageChange;
  final int countPeriodOne;
  final int countPeriodTwo;

  CategoryComparison({
    required this.name,
    this.icon,
    required this.amountPeriodOne,
    required this.amountPeriodTwo,
    required this.difference,
    required this.percentageChange,
    required this.countPeriodOne,
    required this.countPeriodTwo,
  });

  factory CategoryComparison.fromJson(Map<String, dynamic> json) {
    return CategoryComparison(
      name: json['name'] as String? ?? 'Sin categoría',
      icon: json['icon'] as String?,
      amountPeriodOne: (json['amountPeriodOne'] as num?)?.toDouble() ?? 0.0,
      amountPeriodTwo: (json['amountPeriodTwo'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
      countPeriodOne: json['countPeriodOne'] as int? ?? 0,
      countPeriodTwo: json['countPeriodTwo'] as int? ?? 0,
    );
  }
}

