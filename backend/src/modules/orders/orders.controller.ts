import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import {
  CreateOrderDto,
  UpdateOrderStatusDto,
  AssignDriverDto,
  PostponeOrderDto,
  DeliverOrderDto,
  QueryOrdersDto,
} from './dto/orders.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../../common/enums/roles.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { User } from '../../database/entities/user.entity';

@ApiTags('Orders & Waybills')
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Public()
  @Post()
  @ApiOperation({ summary: 'Create a new order (E-Commerce Storefront or Admin)' })
  async create(@Body() createOrderDto: CreateOrderDto, @CurrentUser() user?: User) {
    return this.ordersService.create(createOrderDto, user);
  }

  @Public()
  @Get('track/:orderNumber')
  @ApiOperation({ summary: 'Public Order Tracking Timeline by Order Number' })
  async trackOrder(@Param('orderNumber') orderNumber: string) {
    return this.ordersService.getTrackingHistory(orderNumber);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @Get()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List and filter all orders with pagination & status filters (Admin)' })
  async findAll(@Query() query: QueryOrdersDto) {
    return this.ordersService.findAll(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DRIVER)
  @Get('driver/assigned')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get assigned orders for current logged-in driver' })
  async getDriverAssigned(@CurrentUser() driver: User, @Query('status') status?: OrderStatus) {
    return this.ordersService.findDriverAssignedOrders(driver.id, status);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get order details by ID' })
  async findOne(@Param('id') id: string) {
    return this.ordersService.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @Get(':id/waybill')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate printable Waybill and QR code' })
  async getWaybill(@Param('id') id: string) {
    return this.ordersService.getWaybillData(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @Put(':id/assign-driver')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Assign order to driver with scheduled delivery date' })
  async assignDriver(
    @Param('id') id: string,
    @Body() assignDriverDto: AssignDriverDto,
    @CurrentUser() user: User,
  ) {
    return this.ordersService.assignDriver(id, assignDriverDto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @Patch(':id/status')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update order lifecycle status' })
  async updateStatus(
    @Param('id') id: string,
    @Body() updateDto: UpdateOrderStatusDto,
    @CurrentUser() user: User,
  ) {
    return this.ordersService.updateStatus(id, updateDto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DRIVER, UserRole.ADMIN)
  @Post(':id/deliver')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Driver marks order as delivered, collects COD and captures signature' })
  async deliverOrder(
    @Param('id') id: string,
    @Body() deliverDto: DeliverOrderDto,
    @CurrentUser() user: User,
  ) {
    return this.ordersService.deliverOrder(id, deliverDto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DRIVER, UserRole.ADMIN)
  @Post(':id/postpone')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Driver postpones delivery with mandatory structured reason' })
  async postponeOrder(
    @Param('id') id: string,
    @Body() postponeDto: PostponeOrderDto,
    @CurrentUser() user: User,
  ) {
    return this.ordersService.postponeOrder(id, postponeDto, user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @Post('bulk-scan-update')
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Bulk update orders from USB / Camera barcode scans' })
  async bulkScanUpdate(
    @Body() body: { barcodes: string[]; target_status: OrderStatus },
    @CurrentUser() user: User,
  ) {
    return this.ordersService.bulkUpdateStatusViaScan(body.barcodes, body.target_status, user);
  }
}
