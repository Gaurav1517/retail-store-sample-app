package com.amazon.sample.ui.web;

import com.amazon.sample.ui.services.orders.OrdersService;
import com.amazon.sample.ui.web.util.RequiresCommonAttributes;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/orders")
@Slf4j
@RequiresCommonAttributes
public class OrdersController {

  private OrdersService ordersService;

  public OrdersController(@Autowired OrdersService ordersService) {
    this.ordersService = ordersService;
  }

  @GetMapping
  public String orders(Model model) {
    model.addAttribute("orders", this.ordersService.getOrders());
    return "orders";
  }
}
