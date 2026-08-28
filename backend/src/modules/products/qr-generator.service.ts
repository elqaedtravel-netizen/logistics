import { Injectable, Logger } from '@nestjs/common';
import * as QRCode from 'qrcode';

@Injectable()
export class QrGeneratorService {
  private readonly logger = new Logger(QrGeneratorService.name);

  async generateProductQrPayload(sku: string, price: number, name: string): Promise<string> {
    return `SKU:${sku}|PRICE:${price}|NAME:${name.replace(/\|/g, '')}`;
  }

  async generateDataUrl(payload: string): Promise<string> {
    try {
      return await QRCode.toDataURL(payload, {
        errorCorrectionLevel: 'M',
        type: 'image/png',
        margin: 2,
        width: 300,
        color: {
          dark: '#000000',
          light: '#ffffff',
        },
      });
    } catch (err) {
      this.logger.error(`Failed to generate QR Data URL: ${err.message}`);
      throw err;
    }
  }

  async generateWaybillQrPayload(
    orderNumber: string,
    totalAmount: number,
    isCod: boolean,
    customerPhone: string,
  ): Promise<string> {
    const paymentTag = isCod ? `COD:${totalAmount}` : `PREPAID:${totalAmount}`;
    return `WAYBILL:${orderNumber}|${paymentTag}|PHONE:${customerPhone}|V:1.0`;
  }
}
