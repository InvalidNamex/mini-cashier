import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pos_cubit.dart';
import '../bloc/pos_state.dart';
import '../../../core/database/orders_dao.dart';
import '../../invoice/services/invoice_service.dart';
import '../services/period_report_service.dart';
import 'package:printing/printing.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late PosCubit _posCubit;

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f12) {
      final state = _posCubit.state;
      if (state.activeTab?.cartItems.isNotEmpty == true && mounted) {
        _doCheckout(context, _posCubit);
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _posCubit = context.read<PosCubit>();
    _posCubit.initialize();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (ctx, state) {
        final cubit = ctx.read<PosCubit>();
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF5F7FA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Image.asset('assets/images/cashier.png', height: 40),
                  const SizedBox(width: 12),
                  const Text('نظام المبيعات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: Row(
                children: [
                  // Left: item browser
                  Expanded(
                    flex: 65,
                    child: Column(
                      children: [
                        _buildTabBar(ctx, state, cubit),
                        _buildCategoryChips(ctx, state, cubit),
                        Expanded(child: _buildItemGrid(ctx, state, cubit)),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // Right: cart
                  SizedBox(
                    width: 340,
                    child: _buildCart(ctx, state, cubit),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext ctx, PosState state, PosCubit cubit) {
    return Container(
      color: const Color(0xFFF0F0F0),
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.tabs.length,
              itemBuilder: (_, i) {
                final tab = state.tabs[i];
                final isActive = tab.tabId == state.activeTabId;
                return GestureDetector(
                  onTap: () => cubit.switchTab(tab.tabId),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1A237E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'طلب ${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black87,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (state.tabs.length > 1) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => cubit.removeTab(tab.tabId),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: isActive
                                  ? Colors.white70
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: cubit.addTab,
            tooltip: 'طلب جديد',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(
      BuildContext ctx, PosState state, PosCubit cubit) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: const Text('الكل'),
              selected: state.selectedCategoryId == null,
              onSelected: (_) => cubit.selectCategory(null),
              selectedColor: const Color(0xFF1A237E),
              labelStyle: TextStyle(
                color: state.selectedCategoryId == null
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          ...state.categories.map((cat) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: state.selectedCategoryId == cat.id,
                  onSelected: (_) => cubit.selectCategory(cat.id),
                  selectedColor: const Color(0xFF1A237E),
                  labelStyle: TextStyle(
                    color: state.selectedCategoryId == cat.id
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildItemGrid(BuildContext ctx, PosState state, PosCubit cubit) {
    final items = state.filteredItems;
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد أصناف'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          onTap: () => cubit.addItemToActiveTab(item),
          borderRadius: BorderRadius.circular(10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fastfood_outlined,
                      size: 28, color: Color(0xFF1A237E)),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                        color: Color(0xFF1A237E), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCart(BuildContext ctx, PosState state, PosCubit cubit) {
    final tab = state.activeTab;
    final cartItems = tab?.cartItems ?? [];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          width: double.infinity,
          child: const Text(
            'الطلب الحالي',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        // Close-period button
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.lock_clock_outlined,
                color: Color(0xFF1A237E)),
            label: Text(
              'إغلاق الفترة${state.currentPeriodId != null ? " (${state.currentPeriodId})" : ""}',
              style: const TextStyle(color: Color(0xFF1A237E)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A237E)),
            ),
            onPressed: () => _doClosePeriod(ctx, cubit),
          ),
        ),
        Expanded(
          child: cartItems.isEmpty
              ? const Center(
                  child: Text('أضف أصنافاً من القائمة',
                      style: TextStyle(color: Colors.black45)))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ci = cartItems[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(ci.name,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                              '${ci.unitPrice.toStringAsFixed(2)} ج.م × ${ci.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.comment_outlined,
                                  size: 18,
                                  color: ci.note != null
                                      ? const Color(0xFF1A237E)
                                      : Colors.black38,
                                ),
                                tooltip: 'ملاحظة للصنف',
                                onPressed: () =>
                                    _showItemNoteDialog(ctx, cubit, ci),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 18),
                                onPressed: () => cubit.decreaseQty(ci),
                              ),
                              Text('${ci.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                onPressed: () => cubit.increaseQty(ci),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () => cubit.removeCartItem(ci),
                              ),
                            ],
                          ),
                        ),
                        if (ci.note != null && ci.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 16, left: 8, bottom: 4),
                            child: Text(
                              '📝 ${ci.note}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'ملاحظات الفاتورة',
              hintText: 'أضف ملاحظة للفاتورة...',
              prefixIcon: Icon(Icons.note_outlined),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            minLines: 1,
            onChanged: (v) => cubit.setInvoiceNotes(v),
            controller: TextEditingController(text: tab?.notes ?? '')
              ..selection = TextSelection.collapsed(
                  offset: (tab?.notes ?? '').length),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي:',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${(tab?.total ?? 0).toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red),
                      label: const Text('إلغاء',
                          style: TextStyle(color: Colors.red)),
                      onPressed: cartItems.isEmpty
                          ? null
                          : () => cubit.cancelActiveTab(),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('دفع'),
                      onPressed: cartItems.isEmpty
                          ? null
                          : () => _doCheckout(ctx, cubit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showItemNoteDialog(
      BuildContext ctx, PosCubit cubit, CartItem ci) {
    final ctrl = TextEditingController(text: ci.note ?? '');
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: Text('ملاحظة: ${ci.name}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'أدخل ملاحظة...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 3,
          minLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.setCartItemNote(
                  ci, ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
              Navigator.pop(dlgCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _doCheckout(BuildContext ctx, PosCubit cubit) async {
    final ordersDao = ctx.read<OrdersDao>();
    final cashierUsername = cubit.cashierName;
    final order = await cubit.checkoutActiveTab();
    if (order == null || !ctx.mounted) return;
    final orderItems = await ordersDao.itemsForOrder(order.id);
    if (!ctx.mounted) return;
    final pdfDoc = await InvoiceService.generate(
      order: order,
      orderItems: orderItems,
      cashierName: cashierUsername,
    );
    final pdfBytes = await pdfDoc.save();

    // Try to print directly to the default printer without a preview dialog.
    // Falls back to layoutPdf on web or when no printer is available.
    bool printed = false;
    try {
      final printers = await Printing.listPrinters();
      if (printers.isNotEmpty) {
        final printer = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (_) async => pdfBytes,
        );
        printed = true;
      }
    } catch (_) {
      // directPrintPdf is not supported on this platform (e.g. web).
    }

    if (!printed) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  }

  Future<void> _doClosePeriod(BuildContext ctx, PosCubit cubit) async {
    // Confirm
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Color(0xFF1A237E)),
            SizedBox(width: 8),
            Text('إغلاق الفترة'),
          ],
        ),
        content: const Text(
          'هل تريد إغلاق الفترة الحالية؟\n'
          'سيتم طباعة تقرير المبيعات حسب الفئة وبدء فترة جديدة.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E)),
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: const Text('إغلاق وطباعة',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    final result = await cubit.closePeriod();
    if (result == null || !ctx.mounted) return;

    final pdfDoc = await PeriodReportService.generate(
      period: result.period,
      categoryRevenues: result.categoryRevenues,
      cashierName: cubit.cashierName,
    );
    final pdfBytes = await pdfDoc.save();

    bool printed = false;
    try {
      final printers = await Printing.listPrinters();
      if (printers.isNotEmpty) {
        final printer = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (_) async => pdfBytes,
        );
        printed = true;
      }
    } catch (_) {}

    if (!printed) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    }
  }
}
