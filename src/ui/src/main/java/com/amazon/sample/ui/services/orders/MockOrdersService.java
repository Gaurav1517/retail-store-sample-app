package com.amazon.sample.ui.services.orders;

import com.amazon.sample.ui.client.orders.models.ExistingOrder;
import java.time.OffsetDateTime;
import java.util.Arrays;
import java.util.List;

public class MockOrdersService implements OrdersService {

  @Override
  public List<ExistingOrder> getOrders() {
    // Mock data for development/testing
    ExistingOrder mockOrder = new ExistingOrder();
    mockOrder.setId("mock-order-123");
    mockOrder.setCreatedDate(OffsetDateTime.now().minusDays(1));
    // Add mock items and shipping address as needed

    return Arrays.asList(mockOrder);
  }
}
