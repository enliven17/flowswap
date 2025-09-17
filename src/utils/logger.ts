export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

export interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: Date;
  context?: Record<string, unknown>;
}

class Logger {
  private static instance: Logger;
  private logLevel: LogLevel = LogLevel.INFO;
  private logs: LogEntry[] = [];
  private maxLogs = 1000;

  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  setLogLevel(level: LogLevel): void {
    this.logLevel = level;
  }

  private log(level: LogLevel, message: string, context?: Record<string, unknown>): void {
    if (level < this.logLevel) return;

    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date(),
      context,
    };

    this.logs.push(entry);
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }

    if (process.env.NODE_ENV === 'development') {
      const levelName = LogLevel[level];
      const timestamp = entry.timestamp.toISOString();
      const contextStr = context ? JSON.stringify(context, null, 2) : '';
      
      switch (level) {
        case LogLevel.DEBUG:
          console.debug(`[${timestamp}] DEBUG: ${message}`, contextStr);
          break;
        case LogLevel.INFO:
          console.info(`[${timestamp}] INFO: ${message}`, contextStr);
          break;
        case LogLevel.WARN:
          console.warn(`[${timestamp}] WARN: ${message}`, contextStr);
          break;
        case LogLevel.ERROR:
          console.error(`[${timestamp}] ERROR: ${message}`, contextStr);
          break;
      }
    }
  }

  debug(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  info(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.INFO, message, context);
  }

  warn(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.WARN, message, context);
  }

  error(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.ERROR, message, context);
  }

  getLogs(): LogEntry[] {
    return [...this.logs];
  }

  clearLogs(): void {
    this.logs = [];
  }
}

export const logger = Logger.getInstance();