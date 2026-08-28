import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../database/entities/product.entity';
import { CreateProductDto, UpdateProductDto } from './dto/products.dto';
import { QrGeneratorService } from './qr-generator.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    private qrGeneratorService: QrGeneratorService,
  ) {}

  async findAll(category?: string, search?: string, activeOnly = true) {
    const query = this.productRepository.createQueryBuilder('p');

    if (activeOnly) {
      query.andWhere('p.is_active = :isActive', { isActive: true });
    }

    if (category && category !== 'All') {
      query.andWhere('p.category = :category', { category });
    }

    if (search) {
      query.andWhere('(LOWER(p.name) LIKE :search OR LOWER(p.sku) LIKE :search)', {
        search: `%${search.toLowerCase()}%`,
      });
    }

    query.orderBy('p.created_at', 'DESC');
    return query.getMany();
  }

  async findOne(id: string): Promise<Product> {
    const product = await this.productRepository.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }

  async findBySku(sku: string): Promise<Product> {
    const product = await this.productRepository.findOne({ where: { sku } });
    if (!product) {
      throw new NotFoundException(`Product with SKU "${sku}" not found`);
    }
    return product;
  }

  async create(createProductDto: CreateProductDto): Promise<Product> {
    const existing = await this.productRepository.findOne({
      where: { sku: createProductDto.sku.toUpperCase() },
    });
    if (existing) {
      throw new ConflictException(`SKU ${createProductDto.sku} is already registered`);
    }

    const qrData = await this.qrGeneratorService.generateProductQrPayload(
      createProductDto.sku.toUpperCase(),
      createProductDto.price,
      createProductDto.name,
    );

    const product = this.productRepository.create({
      ...createProductDto,
      sku: createProductDto.sku.toUpperCase(),
      barcode_qr_data: qrData,
    });

    return this.productRepository.save(product);
  }

  async update(id: string, updateProductDto: UpdateProductDto): Promise<Product> {
    const product = await this.findOne(id);
    Object.assign(product, updateProductDto);

    // Refresh QR data if price or name changed
    if (updateProductDto.price !== undefined || updateProductDto.name !== undefined) {
      product.barcode_qr_data = await this.qrGeneratorService.generateProductQrPayload(
        product.sku,
        product.price,
        product.name,
      );
    }

    return this.productRepository.save(product);
  }

  async decrementStock(productId: string, quantity: number): Promise<void> {
    const product = await this.findOne(productId);
    if (product.stock_quantity < quantity) {
      throw new BadRequestException(
        `Insufficient stock for ${product.name}. Available: ${product.stock_quantity}, Requested: ${quantity}`,
      );
    }
    product.stock_quantity -= quantity;
    await this.productRepository.save(product);
  }

  async incrementStock(productId: string, quantity: number): Promise<void> {
    const product = await this.findOne(productId);
    product.stock_quantity += quantity;
    await this.productRepository.save(product);
  }

  async getLowStockAlerts(threshold = 5): Promise<Product[]> {
    return this.productRepository
      .createQueryBuilder('p')
      .where('p.stock_quantity <= :threshold', { threshold })
      .andWhere('p.is_active = true')
      .orderBy('p.stock_quantity', 'ASC')
      .getMany();
  }

  async getPrintableQr(id: string): Promise<{ product: Product; qr_data_url: string }> {
    const product = await this.findOne(id);
    const qrDataUrl = await this.qrGeneratorService.generateDataUrl(product.barcode_qr_data);
    return {
      product,
      qr_data_url: qrDataUrl,
    };
  }
}
