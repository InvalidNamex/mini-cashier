import 'package:equatable/equatable.dart';
import '../../../core/database/app_database.dart';

class CartItem extends Equatable {
  final int orderItemId; // 0 means not yet saved to DB
  final int itemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? note;

  CartItem({
    required this.orderItemId,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({
    int? orderItemId,
    int? quantity,
    String? Function()? note,
  }) =>
      CartItem(
        orderItemId: orderItemId ?? this.orderItemId,
        itemId: itemId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        note: note != null ? note() : this.note,
      );

  @override
  List<Object?> get props => [orderItemId, itemId, quantity, note];
}

class PosTab extends Equatable {
  final String tabId;
  final int? orderId;
  final List<CartItem> cartItems;
  final String? notes; // invoice-level notes

  const PosTab({
    required this.tabId,
    this.orderId,
    this.cartItems = const [],
    this.notes,
  });

  double get total =>
      cartItems.fold(0.0, (sum, i) => sum + i.subtotal);

  PosTab copyWith({
    int? orderId,
    List<CartItem>? cartItems,
    String? Function()? notes,
  }) =>
      PosTab(
        tabId: tabId,
        orderId: orderId ?? this.orderId,
        cartItems: cartItems ?? this.cartItems,
        notes: notes != null ? notes() : this.notes,
      );

  @override
  List<Object?> get props => [tabId, orderId, cartItems, notes];
}

class PosState extends Equatable {
  final List<PosTab> tabs;
  final String activeTabId;
  final List<Category> categories;
  final List<Item> items;
  final int? selectedCategoryId;
  final bool isLoading;
  final int? currentPeriodId;

  const PosState({
    this.tabs = const [],
    this.activeTabId = '',
    this.categories = const [],
    this.items = const [],
    this.selectedCategoryId,
    this.isLoading = false,
    this.currentPeriodId,
  });

  PosTab? get activeTab {
    if (activeTabId.isEmpty) return null;
    try {
      return tabs.firstWhere((t) => t.tabId == activeTabId);
    } catch (_) {
      return null;
    }
  }

  List<Item> get filteredItems => selectedCategoryId == null
      ? items
      : items.where((i) => i.categoryId == selectedCategoryId).toList();

  PosState copyWith({
    List<PosTab>? tabs,
    String? activeTabId,
    List<Category>? categories,
    List<Item>? items,
    int? Function()? selectedCategoryId,
    bool? isLoading,
    int? Function()? currentPeriodId,
  }) =>
      PosState(
        tabs: tabs ?? this.tabs,
        activeTabId: activeTabId ?? this.activeTabId,
        categories: categories ?? this.categories,
        items: items ?? this.items,
        selectedCategoryId: selectedCategoryId != null
            ? selectedCategoryId()
            : this.selectedCategoryId,
        isLoading: isLoading ?? this.isLoading,
        currentPeriodId: currentPeriodId != null
            ? currentPeriodId()
            : this.currentPeriodId,
      );

  @override
  List<Object?> get props =>
      [tabs, activeTabId, categories, items, selectedCategoryId, isLoading, currentPeriodId];
}
