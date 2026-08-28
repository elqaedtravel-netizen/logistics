import { Injectable } from '@nestjs/common';
import { Order } from '../../database/entities/order.entity';
import { QrGeneratorService } from '../products/qr-generator.service';
import { PaymentMethod } from '../../common/enums/payment-method.enum';

@Injectable()
export class WaybillService {
  constructor(private qrGeneratorService: QrGeneratorService) {}

  async generateWaybill(order: Order): Promise<{
    order_number: string;
    waybill_qr_code: string;
    qr_data_url: string;
    printable_waybill: {
      tracking_id: string;
      customer_name: string;
      customer_phone: string;
      shipping_address: string;
      city: string;
      payment_method: string;
      total_to_collect: number;
      created_at: string;
      items_summary: string[];
    };
  }> {
    const isCod = order.payment_method === PaymentMethod.CASH_ON_DELIVERY;
    const qrPayload = await this.qrGeneratorService.generateWaybillQrPayload(
      order.order_number,
      order.total_amount,
      isCod,
      order.customer_phone,
    );

    const qrDataUrl = await this.qrGeneratorService.generateDataUrl(qrPayload);

    const itemsSummary = (order.items || []).map(
      (item) => `${item.product_name} (x${item.quantity}) - ${item.total_price} EGP`,
    );

    return {
      order_number: order.order_number,
      waybill_qr_code: qrPayload,
      qr_data_url: qrDataUrl,
      printable_waybill: {
        tracking_id: order.order_number,
        customer_name: order.customer_name,
        customer_phone: order.customer_phone,
        shipping_address: order.shipping_address,
        city: order.city,
        payment_method: order.payment_method,
        total_to_collect: isCod ? Number(order.total_amount) : 0,
        created_at: order.created_at.toISOString(),
        items_summary: itemsSummary,
      },
    };
  }

  parseScannedBarcode(rawBarcode: string): { orderNumber: string; isWaybill: boolean } {
    const trimmed = rawBarcode.trim();
    if (trimmed.startsWith('WAYBILL:')) {
      const parts = trimmed.split('|');
      const orderPart = parts[0].replace('WAYBILL:', '').trim();
      return { orderNumber: orderPart, isWaybill: true };
    }
    // Direct order number scan e.g., "ORD-2026-10001"
    return { orderNumber: trimmed, isWaybill: trimmed.startsWith('ORD-') };
  }
}
