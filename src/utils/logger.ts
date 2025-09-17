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
  private level: LogLevel;
  private logs: LogEntry[] = [];
  private maxLogs = 1000;

  constructor(level: LogLevel = LogLevel.INFO) {
    this.level = level;
  }

  private log(level: LogLevel, message: string, context?: Record<string, unknown>) {
    if (level < this.level) return;

    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date(),
      context,
    };

    this.logs.push(entry);
    
    // Keep only the last maxLogs entries
    if (this.logs.length > this.maxLogs) {
      this.logs = this.logs.slice(-this.maxLogs);
    }

    // Console output in development
    if (process.env.NODE_ENV === 'development') {
      const levelName = LogLevel[level];
      const timestamp = entry.timestamp.toISOString();
      const contextStr = context ? ` ${JSON.stringify(context)}` : '';
      
      switch (level) {
        case LogLevel.DEBUG:
          console.debug(`[${timestamp}] DEBUG: ${message}${contextStr}`);
          break;
        case LogLevel.INFO:
          console.info(`[${timestamp}] INFO: ${message}${contextStr}`);
          break;
        case LogLevel.WARN:
          console.warn(`[${timestamp}] WARN: ${message}${contextStr}`);
          break;
        case LogLevel.ERROR:
          console.error(`[${timestamp}] ERROR: ${message}${contextStr}`);
          break;
      }
    }
  }

  debug(message: string, context?: Record<string, unknown>) {
    this.log(LogLevel.DEBUG, message, context);
  }

  info(message: string, context?: Record<string, unknown>) {
    this.log(LogLevel.INFO, message, context);
  }

  warn(message: string, context?: Record<string, unknown>) {
    this.log(LogLevel.WARN, message, context);
  }

  error(message: string, context?: Record<string, unknown>) {
    this.log(LogLevel.ERROR, message, context);
  }

  getLogs(): LogEntry[] {
    return [...this.logs];
  }

  clearLogs() {
    this.logs = [];
  }

  setLevel(level: LogLevel) {
    this.level = level;
  }
}

export const logger = new Logger(
  process.env.NODE_ENV === 'development' ? LogLevel.DEBUG : LogLevel.INFO
);