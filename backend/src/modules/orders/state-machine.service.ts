import { Injectable, BadRequestException } from '@nestjs/common';
import { OrderStatus } from '../../common/enums/order-status.enum';

@Injectable()
export class OrderStateMachineService {
  private readonly validTransitions: Record<OrderStatus, OrderStatus[]> = {
    [OrderStatus.Pending]: [OrderStatus.In_Warehouse, OrderStatus.Canceled],
    [OrderStatus.In_Warehouse]: [OrderStatus.Dispatched_to_Driver, OrderStatus.Canceled],
    [OrderStatus.Dispatched_to_Driver]: [
      OrderStatus.Delivered,
      OrderStatus.Postponed,
      OrderStatus.Returned,
      OrderStatus.In_Warehouse, // If driver returns package to warehouse without delivery
    ],
    [OrderStatus.Postponed]: [
      OrderStatus.Dispatched_to_Driver,
      OrderStatus.In_Warehouse,
      OrderStatus.Canceled,
      OrderStatus.Returned,
    ],
    [OrderStatus.Delivered]: [
      OrderStatus.Returned, // Admin/Customer return request
    ],
    [OrderStatus.Canceled]: [], // Terminal state
    [OrderStatus.Returned]: [], // Terminal state
  };

  validateTransition(currentStatus: OrderStatus, newStatus: OrderStatus, isAdminOverride = false): void {
    if (currentStatus === newStatus) {
      return;
    }

    if (isAdminOverride) {
      return;
    }

    const allowed = this.validTransitions[currentStatus] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestException(
        `Illegal Order State Transition: Cannot move order status from "${currentStatus}" to "${newStatus}". Allowed next states: [${allowed.join(', ') || 'None (Terminal state)'}]`,
      );
    }
  }

  isTerminal(status: OrderStatus): boolean {
    return status === OrderStatus.Canceled || status === OrderStatus.Returned;
  }
}
