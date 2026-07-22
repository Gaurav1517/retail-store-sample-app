package com.amazon.sample.ui.services.orders;

import com.amazon.sample.ui.client.orders.OrdersClient;
import com.amazon.sample.ui.client.orders.models.ExistingOrder;
import java.util.List;

public interface OrdersService {
  List<ExistingOrder> getOrders();
}
