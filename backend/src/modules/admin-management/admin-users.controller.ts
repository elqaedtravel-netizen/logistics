import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AdminUsersService, CreateAdminUserDto } from './admin-users.service';
import { User, UserRole } from '../../database/entities/user.entity';

@ApiTags('Admin Users & RBAC (إدارة المديرين والمناديب وتحديد الصلاحيات)')
@Controller('admin/users')
export class AdminUsersController {
  constructor(private readonly adminUsersService: AdminUsersService) {}

  @Post()
  @ApiOperation({
    summary:
      'تسجيل مدير جديد (مدير فرع / مسؤول مالية / مدير عمليات) أو مندوب وتحديد صلاحياته',
  })
  async createUser(@Body() dto: CreateAdminUserDto): Promise<User> {
    return this.adminUsersService.createUser(dto);
  }

  @Get()
  @ApiOperation({
    summary: 'عرض قائمة كافة المديرين والمناديب مع تصفية حسب الدور الوظيفي',
  })
  async listUsers(@Query('role') role?: UserRole): Promise<User[]> {
    return this.adminUsersService.listUsers(role);
  }

  @Put(':id/permissions')
  @ApiOperation({
    summary: 'تعديل وتخصيص صلاحيات مدير محدد بالنظام',
  })
  async updatePermissions(
    @Param('id') userId: string,
    @Body('permissions') permissions: string[],
  ): Promise<User> {
    return this.adminUsersService.updateUserPermissions(userId, permissions);
  }

  @Put(':id/toggle-status')
  @ApiOperation({
    summary: 'تفعيل أو تعطيل حساب مستخدم / مندوب',
  })
  async toggleStatus(@Param('id') userId: string): Promise<User> {
    return this.adminUsersService.toggleUserStatus(userId);
  }
}
