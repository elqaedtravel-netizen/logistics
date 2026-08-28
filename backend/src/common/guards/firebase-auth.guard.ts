import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid Authorization header');
    }

    const token = authHeader.split('Bearer ')[1];

    try {
      if (admin.apps.length > 0) {
        const decodedToken = await admin.auth().verifyIdToken(token);
        request.firebaseUser = decodedToken;
        return true;
      }
      // If Firebase Admin isn't initialized yet in development, allow mock parsing if test token
      if (process.env.NODE_ENV === 'development' && token.startsWith('test_firebase_')) {
        request.firebaseUser = { uid: token, email: `${token}@firebase.mock` };
        return true;
      }
      throw new UnauthorizedException('Firebase authentication unavailable');
    } catch (error) {
      throw new UnauthorizedException(`Invalid Firebase token: ${error.message}`);
    }
  }
}
