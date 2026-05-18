import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/app_database.dart';
import '../cubit/users_cubit.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UsersCubit>().loadCashiers();
  }

  void _showAddDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة كاشير'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: userCtrl,
                decoration:
                    const InputDecoration(labelText: 'اسم المستخدم'),
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                decoration:
                    const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context
                    .read<UsersCubit>()
                    .createCashier(userCtrl.text, passCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(User user) {
    final userCtrl = TextEditingController(text: user.username);
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الكاشير'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: userCtrl,
                decoration:
                    const InputDecoration(labelText: 'اسم المستخدم'),
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  hintText: 'اتركها فارغة للإبقاء على الحالية',
                ),
                obscureText: true,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<UsersCubit>().updateCashier(
                      user.id,
                      userCtrl.text,
                      passCtrl.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكاشير'),
        content: Text('هل تريد حذف "$username"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<UsersCubit>().deleteCashier(id);
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
        title: const Text('إدارة الكاشيرين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'إضافة كاشير',
            onPressed: _showAddDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<UsersCubit, UsersState>(
        listener: (ctx, state) {
          if (state is UsersError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is UsersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UsersLoaded) {
            if (state.cashiers.isEmpty) {
              return const Center(
                child: Text('لا يوجد كاشيرين، أضف واحداً من الأعلى'),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('م')),
                  DataColumn(label: Text('اسم المستخدم')),
                  DataColumn(label: Text('إجراءات')),
                ],
                rows: state.cashiers
                    .map(
                      (u) => DataRow(cells: [
                        DataCell(Text(u.id.toString())),
                        DataCell(Text(u.username)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Color(0xFF1A237E)),
                                onPressed: () => _showEditDialog(u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    _confirmDelete(u.id, u.username),
                              ),
                            ],
                          ),
                        ),
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
