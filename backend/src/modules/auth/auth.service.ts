import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as admin from 'firebase-admin';
import { User } from '../../database/entities/user.entity';
import { LoginDto, RegisterDto, FirebaseLoginDto } from './dto/auth.dto';
import { UserRole } from '../../common/enums/roles.enum';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    const existing = await this.userRepository.findOne({
      where: { email: registerDto.email.toLowerCase() },
    });

    if (existing) {
      throw new ConflictException('A user with this email address already exists');
    }

    const passwordHash = await bcrypt.hash(registerDto.password, 10);

    const user = this.userRepository.create({
      email: registerDto.email.toLowerCase(),
      password_hash: passwordHash,
      full_name: registerDto.full_name,
      phone: registerDto.phone,
      role: registerDto.role || UserRole.CUSTOMER,
      is_active: true,
    });

    const savedUser = await this.userRepository.save(user);
    const token = this.generateToken(savedUser);

    return {
      user: this.sanitizeUser(savedUser),
      token,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.userRepository.findOne({
      where: { email: loginDto.email.toLowerCase() },
    });

    if (!user || !user.password_hash) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(loginDto.password, user.password_hash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (!user.is_active) {
      throw new UnauthorizedException('This account has been deactivated. Please contact support.');
    }

    const token = this.generateToken(user);

    return {
      user: this.sanitizeUser(user),
      token,
    };
  }

  async loginWithFirebase(firebaseLoginDto: FirebaseLoginDto) {
    try {
      let firebaseUid: string;
      let email: string;
      let name: string;

      if (admin.apps.length > 0) {
        const decoded = await admin.auth().verifyIdToken(firebaseLoginDto.id_token);
        firebaseUid = decoded.uid;
        email = decoded.email || `${decoded.uid}@google.auth`;
        name = decoded.name || firebaseLoginDto.full_name || 'Google User';
      } else {
        // Fallback for local sandbox/development mode
        this.logger.warn('Firebase Admin not initialized with live credentials. Parsing payload token.');
        firebaseUid = `fb_uid_${Buffer.from(firebaseLoginDto.id_token.substring(0, 16)).toString('hex')}`;
        email = `google_user_${firebaseUid.substring(0, 8)}@gmail.com`;
        name = firebaseLoginDto.full_name || 'Verified Google User';
      }

      let user = await this.userRepository.findOne({
        where: [{ firebase_uid: firebaseUid }, { email: email.toLowerCase() }],
      });

      if (!user) {
        user = this.userRepository.create({
          email: email.toLowerCase(),
          firebase_uid: firebaseUid,
          full_name: name,
          role: UserRole.CUSTOMER,
          is_active: true,
          fcm_token: firebaseLoginDto.fcm_token,
        });
      } else {
        if (!user.firebase_uid) {
          user.firebase_uid = firebaseUid;
        }
        if (firebaseLoginDto.fcm_token) {
          user.fcm_token = firebaseLoginDto.fcm_token;
        }
      }

      const savedUser = await this.userRepository.save(user);
      const token = this.generateToken(savedUser);

      return {
        user: this.sanitizeUser(savedUser),
        token,
      };
    } catch (error) {
      this.logger.error(`Firebase token verification failed: ${error.message}`);
      throw new UnauthorizedException(`Google Authentication failed: ${error.message}`);
    }
  }

  private generateToken(user: User): string {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      name: user.full_name,
    };
    return this.jwtService.sign(payload);
  }

  public sanitizeUser(user: User) {
    const { password_hash, ...sanitized } = user;
    return sanitized;
  }
}
