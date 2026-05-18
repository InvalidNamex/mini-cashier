import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../cubit/categories_cubit.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().load();
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    void submit(BuildContext ctx) {
      if (formKey.currentState!.validate()) {
        context.read<CategoriesCubit>().add(ctrl.text);
        Navigator.pop(ctx);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فئة'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'اسم الفئة'),
            autofocus: true,
            onFieldSubmitted: (_) => submit(ctx),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => submit(ctx),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Category cat) {
    final ctrl = TextEditingController(text: cat.name);
    final formKey = GlobalKey<FormState>();

    void submit(BuildContext ctx) {
      if (formKey.currentState!.validate()) {
        context.read<CategoriesCubit>().update(cat.id, ctrl.text);
        Navigator.pop(ctx);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الفئة'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'اسم الفئة'),
            autofocus: true,
            onFieldSubmitted: (_) => submit(ctx),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => submit(ctx),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل تريد حذف "${cat.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CategoriesCubit>().delete(cat.id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفئات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة فئة',
            onPressed: _showAddDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (ctx, state) {
          if (state is CategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoriesLoaded) {
            if (state.items.isEmpty) {
              return const Center(
                  child: Text('لا توجد فئات، أضف فئة من الأعلى'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('م')),
                  DataColumn(label: Text('اسم الفئة')),
                  DataColumn(label: Text('إجراءات')),
                ],
                rows: state.items
                    .map(
                      (c) => DataRow(cells: [
                        DataCell(Text(c.id.toString())),
                        DataCell(Text(c.name)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF1A237E)),
                              onPressed: () => _showEditDialog(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _confirmDelete(c),
                            ),
                          ],
                        )),
                      ]),
                    )
                    .toList(),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
