// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/jalali_helper.dart';
import '../../data/models/finance_inventory_models.dart';
import '../../data/storage/local_storage_service.dart';

class InventoryFinancePage extends StatefulWidget {
  final LocalStorageService storageService;
  final int dataVersion;
    final int refreshToken;
  final VoidCallback onDataChanged;

  const InventoryFinancePage({
    super.key,
    required this.storageService,
    required this.dataVersion,
    this.refreshToken = 0,    required this.onDataChanged,
  });

  @override
  State<InventoryFinancePage> createState() => _InventoryFinancePageState();
}

class _InventoryFinancePageState extends State<InventoryFinancePage> {
  final Uuid _uuid = const Uuid();

  bool _showFinanceTab = false;
  List<InventoryItem> _items = [];
  List<FinancialEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }
  void _loadData() {
    _items = widget.storageService.getAllInventoryItems();
    _entries = widget.storageService.getAllFinancialEntries();
  }

  void _reload() {
    setState(_loadData);
  }

  @override
  void didUpdateWidget(covariant InventoryFinancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion ||
        oldWidget.refreshToken != widget.refreshToken) {      _loadData();
    }
  }

  Future<void> _adjustStock(InventoryItem item, double delta) async {
    final nextQty = item.quantity + delta;
    if (nextQty < 0) return;

    final updated = item.copyWith(quantity: nextQty, updatedAt: DateTime.now());
    await widget.storageService.upsertInventoryItem(updated);
    _reload();
    widget.onDataChanged();
  }

  Future<void> _showAddInventoryDialog() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '10');
    final thresholdController = TextEditingController(text: '2');
    InventoryUnit selectedUnit = InventoryUnit.kilogram;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('ثبت قلم جدید در انبار'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'نام قلم (مثلاً یونجه یا کنسانتره)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InventoryUnit>(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: 'واحد'),
                      items: InventoryUnit.values
                          .map(
                            (u) => DropdownMenuItem<InventoryUnit>(
                              value: u,
                              child: Text(u.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setDialogState(() => selectedUnit = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'موجودی فعلی',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'حد هشدار کمبود (۰ یعنی بدون هشدار)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('ذخیره'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final qty = double.tryParse(qtyController.text.trim()) ?? 0;
      final threshold = double.tryParse(thresholdController.text.trim()) ?? 0;
      final now = DateTime.now();

      final item = InventoryItem(
        id: _uuid.v4(),
        name: nameController.text.trim(),
        unit: selectedUnit,
        quantity: qty < 0 ? 0 : qty,
        lowStockThreshold: threshold < 0 ? 0 : threshold,
        updatedAt: now,
      );

      await widget.storageService.upsertInventoryItem(item);
      _reload();
      widget.onDataChanged();
    }

    nameController.dispose();
    qtyController.dispose();
    thresholdController.dispose();
  }

  Future<void> _showAddFinanceDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    FinanceType selectedType = FinanceType.expense;
    FinanceCategory selectedCategory = FinanceCategory.feed;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('ثبت درآمد یا هزینه'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<FinanceType>(
                      segments: const [
                        ButtonSegment<FinanceType>(
                          value: FinanceType.expense,
                          label: Text('هزینه'),
                        ),
                        ButtonSegment<FinanceType>(
                          value: FinanceType.income,
                          label: Text('درآمد'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (val) {
                        setDialogState(() => selectedType = val.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FinanceCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                      items: FinanceCategory.values
                          .map(
                            (c) => DropdownMenuItem<FinanceCategory>(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'مبلغ'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'توضیح کوتاه (اختیاری)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('ثبت'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final parsedAmount = double.tryParse(amountController.text.trim()) ?? 0;
      if (parsedAmount > 0) {
        final now = DateTime.now();
        final noteText = noteController.text.trim();
        final entry = FinancialEntry(
          id: _uuid.v4(),
          type: selectedType,
          category: selectedCategory,
          amount: parsedAmount,
          date: now,
          note: noteText.isEmpty ? null : noteText,
          createdAt: now,
        );

        await widget.storageService.addFinancialEntry(entry);
        _reload();
        widget.onDataChanged();
      }
    }

    amountController.dispose();
    noteController.dispose();
  }

  String _formatNumber(double value) {
    final intVal = value.round();
    final str = intVal.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return intVal < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final e in _entries) {
      if (e.type == FinanceType.income) {
        totalIncome += e.amount;
      } else {
        totalExpense += e.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('انبار و دخل‌وخرج'),
        actions: [
          IconButton(
            onPressed: _showFinanceTab
                ? _showAddFinanceDialog
                : _showAddInventoryDialog,
            icon: const Icon(Icons.add_rounded),
            tooltip: _showFinanceTab ? 'ثبت تراکنش' : 'ثبت قلم انبار',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('انبار خوراک و دارو'),
                icon: Icon(Icons.inventory_2_outlined),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('دخل و خرج'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ],
            selected: {_showFinanceTab},
            onSelectionChanged: (val) =>
                setState(() => _showFinanceTab = val.first),
          ),
          const SizedBox(height: 14),
          if (!_showFinanceTab) ...[
            if (_items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'هنوز قلمی در انبار ثبت نشده است. با دکمه + بالای صفحه خوراک یا دارو اضافه کن.',
                    style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                  ),
                ),
              )
            else
              ..._items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'موجودی: ${_formatNumber(item.quantity)} ${item.unit.label}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: item.isLowStock
                                        ? AppTheme.dangerRed
                                        : AppTheme.textMuted,
                                  ),
                                ),
                                if (item.isLowStock) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'هشدار: موجودی رو به اتمام است',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.dangerRed,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _adjustStock(item, -1),
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            onPressed: () => _adjustStock(item, 1),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('کل درآمد:'),
                        Text(
                          _formatNumber(totalIncome),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('کل هزینه:'),
                        Text(
                          _formatNumber(totalExpense),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'تراز خالص:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _formatNumber(netBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: netBalance >= 0
                                ? AppTheme.primaryGreen
                                : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'تراکنش مالی ثبت نشده است. با دکمه + اولین هزینه یا درآمد را ثبت کن.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ..._entries.map((e) {
                final isIncome = e.type == FinanceType.income;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        isIncome
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isIncome
                            ? AppTheme.primaryGreen
                            : AppTheme.dangerRed,
                      ),
                      title: Text(
                        '${e.type.label} • ${e.category.label}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${JalaliHelper.formatReadable(e.date)}'
                        '${e.note != null ? ' • ${e.note}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        _formatNumber(e.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isIncome
                              ? AppTheme.primaryGreen
                              : AppTheme.dangerRed,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
