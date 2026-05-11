import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'pos_state.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/orders_dao.dart';
import '../../../core/database/categories_dao.dart';
import '../../../core/database/items_dao.dart';

class PosCubit extends Cubit<PosState> {
  final OrdersDao _ordersDao;
  final CategoriesDao _categoriesDao;
  final ItemsDao _itemsDao;
  final int cashierId;
  final String cashierName;
  final _uuid = const Uuid();

  PosCubit({
    required this.cashierId,
    required this.cashierName,
    required OrdersDao ordersDao,
    required CategoriesDao categoriesDao,
    required ItemsDao itemsDao,
  })  : _ordersDao = ordersDao,
        _categoriesDao = categoriesDao,
        _itemsDao = itemsDao,
        super(const PosState());

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));
    final cats = await _categoriesDao.allCategories();
    final allItems = await _itemsDao.allItems();

    // Restore open orders as tabs
    final openOrders = await _ordersDao.openOrders();
    final tabs = <PosTab>[];
    for (final order in openOrders) {
      final orderItems = await _ordersDao.itemsForOrder(order.id);
      final cartItems = orderItems
          .map((oi) => CartItem(
                orderItemId: oi.id,
                itemId: oi.itemId,
                name: oi.itemNameSnapshot,
                unitPrice: oi.unitPriceSnapshot,
                quantity: oi.quantity,
                note: oi.note,
              ))
          .toList();
      tabs.add(PosTab(
        tabId: _uuid.v4(),
        orderId: order.id,
        cartItems: cartItems,
      ));
    }

    // Add a default empty tab if none
    if (tabs.isEmpty) {
      tabs.add(PosTab(tabId: _uuid.v4()));
    }

    emit(state.copyWith(
      tabs: tabs,
      activeTabId: tabs.first.tabId,
      categories: cats,
      items: allItems,
      isLoading: false,
    ));
  }

  void addTab() {
    final newTab = PosTab(tabId: _uuid.v4());
    final newTabs = [...state.tabs, newTab];
    emit(state.copyWith(tabs: newTabs, activeTabId: newTab.tabId));
  }

  Future<void> removeTab(String tabId) async {
    final tab = state.tabs.firstWhere((t) => t.tabId == tabId);
    if (tab.orderId != null) {
      await _ordersDao.cancelOrder(tab.orderId!);
    }
    final newTabs = state.tabs.where((t) => t.tabId != tabId).toList();
    if (newTabs.isEmpty) {
      newTabs.add(PosTab(tabId: _uuid.v4()));
    }
    final newActive = newTabs.any((t) => t.tabId == state.activeTabId)
        ? state.activeTabId
        : newTabs.first.tabId;
    emit(state.copyWith(tabs: newTabs, activeTabId: newActive));
  }

  void switchTab(String tabId) {
    emit(state.copyWith(activeTabId: tabId));
  }

  void selectCategory(int? categoryId) {
    emit(state.copyWith(selectedCategoryId: () => categoryId));
  }

  Future<void> addItemToActiveTab(Item item) async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;

    // Ensure order exists in DB
    int orderId;
    if (activeTab.orderId == null) {
      orderId = await _ordersDao.createOrder(cashierId);
    } else {
      orderId = activeTab.orderId!;
    }

    // Check if item already in cart
    final existing = activeTab.cartItems.cast<CartItem?>().firstWhere(
          (ci) => ci!.itemId == item.id,
          orElse: () => null,
        );

    List<CartItem> newCart;
    if (existing != null) {
      final newQty = existing.quantity + 1;
      await _ordersDao.updateOrderItemQty(existing.orderItemId, newQty);
      newCart = activeTab.cartItems
          .map((ci) => ci.itemId == item.id ? ci.copyWith(quantity: newQty) : ci)
          .toList();
    } else {
      final orderItemId = await _ordersDao.addOrderItem(
        orderId: orderId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        unitPriceSnapshot: item.price,
        quantity: 1,
      );
      newCart = [
        ...activeTab.cartItems,
        CartItem(
          orderItemId: orderItemId,
          itemId: item.id,
          name: item.name,
          unitPrice: item.price,
          quantity: 1,
        ),
      ];
    }

    final newTotal =
        newCart.fold(0.0, (sum, ci) => sum + ci.subtotal);
    await _ordersDao.updateOrderTotal(orderId, newTotal);

    final updatedTab = activeTab.copyWith(
      orderId: orderId,
      cartItems: newCart,
    );
    _updateTab(updatedTab);
  }

  Future<void> increaseQty(CartItem cartItem) async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    final newQty = cartItem.quantity + 1;
    await _ordersDao.updateOrderItemQty(cartItem.orderItemId, newQty);
    final newCart = activeTab.cartItems
        .map((ci) =>
            ci.orderItemId == cartItem.orderItemId
                ? ci.copyWith(quantity: newQty)
                : ci)
        .toList();
    final newTotal =
        newCart.fold(0.0, (sum, ci) => sum + ci.subtotal);
    if (activeTab.orderId != null) {
      await _ordersDao.updateOrderTotal(activeTab.orderId!, newTotal);
    }
    _updateTab(activeTab.copyWith(cartItems: newCart));
  }

  Future<void> decreaseQty(CartItem cartItem) async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    if (cartItem.quantity <= 1) {
      await removeCartItem(cartItem);
      return;
    }
    final newQty = cartItem.quantity - 1;
    await _ordersDao.updateOrderItemQty(cartItem.orderItemId, newQty);
    final newCart = activeTab.cartItems
        .map((ci) =>
            ci.orderItemId == cartItem.orderItemId
                ? ci.copyWith(quantity: newQty)
                : ci)
        .toList();
    final newTotal =
        newCart.fold(0.0, (sum, ci) => sum + ci.subtotal);
    if (activeTab.orderId != null) {
      await _ordersDao.updateOrderTotal(activeTab.orderId!, newTotal);
    }
    _updateTab(activeTab.copyWith(cartItems: newCart));
  }

  Future<void> removeCartItem(CartItem cartItem) async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    await _ordersDao.removeOrderItem(cartItem.orderItemId);
    final newCart = activeTab.cartItems
        .where((ci) => ci.orderItemId != cartItem.orderItemId)
        .toList();
    final newTotal =
        newCart.fold(0.0, (sum, ci) => sum + ci.subtotal);
    if (activeTab.orderId != null) {
      await _ordersDao.updateOrderTotal(activeTab.orderId!, newTotal);
    }
    _updateTab(activeTab.copyWith(cartItems: newCart));
  }

  Future<void> setCartItemNote(CartItem cartItem, String? note) async {
    if (cartItem.orderItemId == 0) return;
    await _ordersDao.updateOrderItemNote(cartItem.orderItemId, note);
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    final newCart = activeTab.cartItems
        .map((ci) => ci.orderItemId == cartItem.orderItemId
            ? ci.copyWith(note: () => note?.isEmpty == true ? null : note)
            : ci)
        .toList();
    _updateTab(activeTab.copyWith(cartItems: newCart));
  }

  void setInvoiceNotes(String? notes) {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    _updateTab(activeTab.copyWith(
        notes: () => notes?.isEmpty == true ? null : notes));
  }

  /// Returns the completed order for invoice generation.
  Future<Order?> checkoutActiveTab() async {
    final activeTab = state.activeTab;
    if (activeTab == null || activeTab.orderId == null) return null;
    if (activeTab.cartItems.isEmpty) return null;

    final total = activeTab.total;
    await _ordersDao.closeOrder(activeTab.orderId!, total,
        notes: activeTab.notes);
    final order = await _ordersDao.getOrder(activeTab.orderId!);

    // Replace tab with a fresh one
    final newTab = PosTab(tabId: _uuid.v4());
    final newTabs = state.tabs
        .map((t) => t.tabId == activeTab.tabId ? newTab : t)
        .toList();
    emit(state.copyWith(tabs: newTabs, activeTabId: newTab.tabId));
    return order;
  }

  Future<void> cancelActiveTab() async {
    final activeTab = state.activeTab;
    if (activeTab == null) return;
    if (activeTab.orderId != null) {
      await _ordersDao.cancelOrder(activeTab.orderId!);
    }
    final newTab = PosTab(tabId: _uuid.v4());
    final newTabs = state.tabs
        .map((t) => t.tabId == activeTab.tabId ? newTab : t)
        .toList();
    emit(state.copyWith(tabs: newTabs, activeTabId: newTab.tabId));
  }

  void _updateTab(PosTab updated) {
    final newTabs =
        state.tabs.map((t) => t.tabId == updated.tabId ? updated : t).toList();
    emit(state.copyWith(tabs: newTabs));
  }
}
