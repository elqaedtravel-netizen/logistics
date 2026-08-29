import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getTypeOrmConfig = (configService: ConfigService): TypeOrmModuleOptions => {
  const url = configService.get<string>('database.url');
  const isRemoteHost = configService.get<string>('database.host')?.includes('supabase.co');
  const isSslEnabled = configService.get<boolean>('database.ssl') || isRemoteHost;

  if (url) {
    return {
      type: 'postgres',
      url,
      ssl: isSslEnabled ? { rejectUnauthorized: false } : false,
      entities: [__dirname + '/../database/entities/*.entity{.ts,.js}'],
      synchronize: configService.get<boolean>('database.synchronize') ?? true,
      logging: configService.get<boolean>('database.logging') ?? false,
      autoLoadEntities: true,
    };
  }

  return {
    type: 'postgres',
    host: configService.get<string>('database.host'),
    port: configService.get<number>('database.port'),
    username: configService.get<string>('database.username'),
    password: configService.get<string>('database.password'),
    database: configService.get<string>('database.database'),
    ssl: isSslEnabled ? { rejectUnauthorized: false } : false,
    entities: [__dirname + '/../database/entities/*.entity{.ts,.js}'],
    synchronize: configService.get<boolean>('database.synchronize') ?? true,
    logging: configService.get<boolean>('database.logging') ?? false,
    autoLoadEntities: true,
  };
};
