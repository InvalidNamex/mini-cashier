import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/arabic_utils.dart';
import '../cubit/items_cubit.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  int? _filterCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ItemsCubit>().load();
  }

  void _showAddDialog(List<Category> cats) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    int? selectedCat = cats.isNotEmpty ? cats.first.id : null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('إضافة صنف'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedCat = v),
                  validator: (v) => v == null ? 'اختر فئة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الصنف'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'السعر (جنيه)'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'مطلوب';
                    final normalized = arabicToEnglishDigits(v.trim());
                    if (double.tryParse(normalized) == null) return 'رقم غير صحيح';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<ItemsCubit>().add(
                        selectedCat!,
                        nameCtrl.text,
                        double.parse(arabicToEnglishDigits(priceCtrl.text.trim())),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Item item, List<Category> cats) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(2));
    int? selectedCat = item.categoryId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('تعديل الصنف'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedCat = v),
                  validator: (v) => v == null ? 'اختر فئة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الصنف'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'السعر (جنيه)'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'مطلوب';
                    final normalized = arabicToEnglishDigits(v.trim());
                    if (double.tryParse(normalized) == null) return 'رقم غير صحيح';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<ItemsCubit>().update(
                        item.id,
                        selectedCat!,
                        nameCtrl.text,
                        double.parse(arabicToEnglishDigits(priceCtrl.text.trim())),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل تريد حذف "${item.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ItemsCubit>().delete(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemsCubit, ItemsState>(
      builder: (ctx, state) {
        final cats = state is ItemsLoaded ? state.categories : <Category>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة الأصناف'),
            actions: [
              if (state is ItemsLoaded)
                DropdownButton<int?>(
                  value: _filterCategoryId,
                  dropdownColor: Colors.white,
                  underline: const SizedBox(),
                  hint: const Text('كل الفئات',
                      style: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white70,
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('كل الفئات',
                            style: TextStyle(color: Colors.black))),
                    ...cats.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              style: const TextStyle(color: Colors.black)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _filterCategoryId = v),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'إضافة صنف',
                onPressed: state is ItemsLoaded && cats.isNotEmpty
                    ? () => _showAddDialog(cats)
                    : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: () {
            if (state is ItemsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ItemsLoaded) {
              final filtered = _filterCategoryId == null
                  ? state.items
                  : state.items
                      .where((i) => i.categoryId == _filterCategoryId)
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('لا توجد أصناف'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('م')),
                    DataColumn(label: Text('الفئة')),
                    DataColumn(label: Text('اسم الصنف')),
                    DataColumn(label: Text('السعر')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: filtered.map((item) {
                    final cat = cats.where((c) => c.id == item.categoryId);
                    final catName = cat.isNotEmpty ? cat.first.name : '—';
                    return DataRow(cells: [
                      DataCell(Text(item.id.toString())),
                      DataCell(Text(catName)),
                      DataCell(Text(item.name)),
                      DataCell(Text('${item.price.toStringAsFixed(2)} ج.م')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFF1B6B4A)),
                            onPressed: () =>
                                _showEditDialog(item, cats),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              );
            }
            return const SizedBox();
          }(),
        );
      },
    );
  }
}
