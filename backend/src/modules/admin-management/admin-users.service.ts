import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../../database/entities/user.entity';

export interface CreateAdminUserDto {
  email: string;
  password: string;
  full_name: string;
  phone?: string;
  role: UserRole;
  permissions?: string[];
  hub_id?: string;
  national_id?: string;
  driving_license_number?: string;
  vehicle_type?: string;
  commission_percentage?: number;
}

@Injectable()
export class AdminUsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async createUser(dto: CreateAdminUserDto): Promise<User> {
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('البريد الإلكتروني مسجل مسبقاً بالنظام');
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(dto.password, salt);

    // Default permissions based on role
    let permissions = dto.permissions || [];
    if (permissions.length === 0) {
      if (dto.role === UserRole.SUPER_ADMIN) {
        permissions = [
          'orders.create',
          'orders.dispatch',
          'finance.settle',
          'inventory.manage',
          'users.manage',
          'settings.edit',
        ];
      } else if (dto.role === UserRole.HUB_MANAGER) {
        permissions = ['orders.create', 'orders.dispatch', 'inventory.manage'];
      } else if (dto.role === UserRole.FINANCE_ADMIN) {
        permissions = ['finance.settle', 'settings.edit'];
      } else if (dto.role === UserRole.OPERATIONS_ADMIN) {
        permissions = ['orders.dispatch', 'orders.create'];
      } else if (dto.role === UserRole.DRIVER) {
        permissions = ['driver.runs', 'driver.pod'];
      }
    }

    const user = this.userRepo.create({
      email: dto.email,
      password_hash,
      full_name: dto.full_name,
      phone: dto.phone,
      role: dto.role,
      permissions,
      hub_id: dto.hub_id,
      national_id: dto.national_id,
      driving_license_number: dto.driving_license_number,
      vehicle_type: dto.vehicle_type || 'موتوسيكل',
      commission_percentage: dto.commission_percentage || 10.0,
      is_active: true,
    });

    return this.userRepo.save(user);
  }

  async listUsers(role?: UserRole): Promise<User[]> {
    if (role) {
      return this.userRepo.find({ where: { role }, order: { created_at: 'DESC' } });
    }
    return this.userRepo.find({ order: { created_at: 'DESC' } });
  }

  async updateUserPermissions(userId: string, permissions: string[]): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('المستخدم غير موجود');

    user.permissions = permissions;
    return this.userRepo.save(user);
  }

  async toggleUserStatus(userId: string): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('المستخدم غير موجود');

    user.is_active = !user.is_active;
    return this.userRepo.save(user);
  }
}
