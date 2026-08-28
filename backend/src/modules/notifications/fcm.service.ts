import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');
    const privateKey = this.configService.get<string>('firebase.privateKey');

    if (projectId && clientEmail && privateKey && admin.apps.length === 0) {
      try {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log('🔥 Firebase Admin SDK initialized successfully.');
      } catch (err) {
        this.logger.warn(`Firebase Admin SDK initialization skipped: ${err.message}`);
      }
    } else {
      this.logger.log('Firebase credentials not fully configured; operating in simulated notification mode.');
    }
  }

  async sendPushNotification(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    if (!fcmToken) {
      return false;
    }

    if (admin.apps.length === 0) {
      this.logger.log(`[SIMULATED FCM PUSH] To: ${fcmToken.substring(0, 12)}... | Title: "${title}" | Body: "${body}"`);
      return true;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      this.logger.log(`FCM Push sent to token ${fcmToken.substring(0, 10)}...`);
      return true;
    } catch (err) {
      this.logger.error(`Failed to send FCM push notification: ${err.message}`);
      return false;
    }
  }
}
