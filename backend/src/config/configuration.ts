export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  apiPrefix: process.env.API_PREFIX || 'api/v1',
  database: {
    url: process.env.DATABASE_URL || '',
    host: process.env.DB_HOST || 'db.ilbwotqmlrsrleebwned.supabase.co',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    username: process.env.DB_USERNAME || process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Aa123456789@123456789$',
    database: process.env.DB_DATABASE || process.env.DB_NAME || 'postgres',
    ssl: process.env.DB_SSL === 'true' || true,
    synchronize: process.env.DB_SYNCHRONIZE !== 'false',
    logging: process.env.DB_LOGGING === 'true',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'super_secret_jwt_key_egypt_logistics_2026_x8891',
    expiresIn: process.env.JWT_EXPIRATION || '7d',
  },
  paymob: {
    apiKey: process.env.PAYMOB_API_KEY || '',
    integrationIdCard: parseInt(process.env.PAYMOB_INTEGRATION_ID_CARD, 10) || 0,
    integrationIdWallet: parseInt(process.env.PAYMOB_INTEGRATION_ID_WALLET, 10) || 0,
    integrationIdMeeza: parseInt(process.env.PAYMOB_INTEGRATION_ID_MEEZA, 10) || 0,
    iframeId: parseInt(process.env.PAYMOB_IFRAME_ID, 10) || 0,
    hmacSecret: process.env.PAYMOB_HMAC_SECRET || '',
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : '',
  },
  driver: {
    defaultCommissionPercentage: parseFloat(process.env.DRIVER_DEFAULT_COMMISSION_PERCENTAGE) || 10.0,
  },
});
