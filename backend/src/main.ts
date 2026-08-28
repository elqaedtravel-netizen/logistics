import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Security Headers
  app.use(helmet());

  // CORS configuration for Flutter Web & Mobile/Desktop clients
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global API Prefix
  app.setGlobalPrefix('api/v1');

  // Global DTO Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // OpenAPI / Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('Antigravity Logistics & E-Commerce API')
    .setDescription(
      'Enterprise backend API for Logistics, Shipping, Order Lifecycle, Inventory QR, Driver Ledger, and Paymob Egypt payment gateway.',
    )
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('Authentication', 'JWT & Google Firebase sign-in endpoints')
    .addTag('Products & Inventory', 'Product catalog, stock management & QR labels')
    .addTag('Orders & Waybills', 'Lifecycle state machine, driver dispatch & tracking')
    .addTag('Users & Driver Management', 'User management, driver performance metrics')
    .addTag('Driver Financials & Ledger', 'Driver COD collection, commissions & payouts')
    .addTag('Egyptian Payment Gateway (Paymob)', 'Card, Meeza, and Mobile Wallet integrations')
    .addTag('Analytics & Executive Reporting', 'Real-time KPIs, revenue & route stats')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`🚀 Antigravity Logistics Backend running on http://localhost:${port}/api/v1`);
  logger.log(`📚 Swagger OpenAPI Documentation available at http://localhost:${port}/api/docs`);
}

bootstrap();
