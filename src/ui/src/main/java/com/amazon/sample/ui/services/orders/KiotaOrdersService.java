package com.amazon.sample.ui.services.orders;

import com.amazon.sample.ui.client.orders.OrdersClient;
import com.amazon.sample.ui.client.orders.models.ExistingOrder;
import com.amazon.sample.ui.util.RetryUtils;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Mono;

@Slf4j
public class KiotaOrdersService implements OrdersService {

  private final OrdersClient ordersClient;

  public KiotaOrdersService(OrdersClient ordersClient) {
    this.ordersClient = ordersClient;
  }

  @Override
  public List<ExistingOrder> getOrders() {
    return Mono.just(this.ordersClient.orders().get())
      .retryWhen(RetryUtils.apiClientRetrySpec("get orders"))
      .block();
  }
}
