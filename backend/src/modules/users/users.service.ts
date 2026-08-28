import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../database/entities/user.entity';
import { Order } from '../../database/entities/order.entity';
import { CreateUserDto, UpdateUserDto } from './dto/users.dto';
import { UserRole } from '../../common/enums/roles.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
  ) {}

  async findAll(role?: UserRole, search?: string): Promise<Omit<User, 'password_hash'>[]> {
    const query = this.userRepository.createQueryBuilder('user');

    if (role) {
      query.andWhere('user.role = :role', { role });
    }

    if (search) {
      query.andWhere(
        '(LOWER(user.full_name) LIKE :search OR LOWER(user.email) LIKE :search OR user.phone LIKE :search)',
        { search: `%${search.toLowerCase()}%` },
      );
    }

    query.orderBy('user.created_at', 'DESC');
    const users = await query.getMany();

    return users.map((u) => {
      const { password_hash, ...rest } = u;
      return rest as any;
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id },
      relations: ['orders_as_driver'],
    });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async create(createUserDto: CreateUserDto): Promise<Omit<User, 'password_hash'>> {
    const existing = await this.userRepository.findOne({
      where: { email: createUserDto.email.toLowerCase() },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const password_hash = await bcrypt.hash(createUserDto.password, 10);
    const user = this.userRepository.create({
      ...createUserDto,
      email: createUserDto.email.toLowerCase(),
      password_hash,
      is_active: true,
    });

    const saved = await this.userRepository.save(user);
    const { password_hash: _, ...result } = saved;
    return result as any;
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<Omit<User, 'password_hash'>> {
    const user = await this.findOne(id);
    Object.assign(user, updateUserDto);
    const updated = await this.userRepository.save(user);
    const { password_hash, ...result } = updated;
    return result as any;
  }

  async getDriverStats(driverId: string) {
    const driver = await this.findOne(driverId);
    if (driver.role !== UserRole.DRIVER) {
      throw new NotFoundException('Specified user is not a driver');
    }

    const orders = await this.orderRepository.find({
      where: { assigned_driver_id: driverId },
    });

    const totalAssigned = orders.length;
    const deliveredCount = orders.filter((o) => o.status === OrderStatus.Delivered).length;
    const postponedCount = orders.filter((o) => o.status === OrderStatus.Postponed).length;
    const activeRouteCount = orders.filter(
      (o) => o.status === OrderStatus.Dispatched_to_Driver,
    ).length;

    const successRate = totalAssigned > 0 ? (deliveredCount / totalAssigned) * 100 : 0;
    const postponementRate = totalAssigned > 0 ? (postponedCount / totalAssigned) * 100 : 0;

    return {
      driver: {
        id: driver.id,
        full_name: driver.full_name,
        email: driver.email,
        phone: driver.phone,
        commission_rate: driver.commission_rate,
      },
      stats: {
        total_assigned: totalAssigned,
        active_in_route: activeRouteCount,
        delivered: deliveredCount,
        postponed: postponedCount,
        success_rate_percentage: parseFloat(successRate.toFixed(2)),
        postponement_rate_percentage: parseFloat(postponementRate.toFixed(2)),
      },
    };
  }
}
