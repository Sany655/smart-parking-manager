// MySQL connection helper compatible with CommonJS (require)
// Exports a `db` object with the same callback-style API used across the codebase.
// It will attempt to run `smart_parking_db.sql` migration automatically if the target database is missing.
// Install dependency: npm install mysql2

const mysqlPromise = require('mysql2/promise');
const mysql = require('mysql2');
const fs = require('fs');
const path = require('path');

const DEFAULTS = {
  host: process.env.MYSQL_HOST || 'localhost',
  user: process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || '',
  database: process.env.MYSQL_DATABASE || 'smart_parking_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

let realPool = null;
let initError = null;
let ready = false;

// queue of pending operations while initialization runs
const pending = [];

function flushPending() {
  while (pending.length > 0) {
    const { method, args } = pending.shift();
    try {
      db[method](...args);
    } catch (e) {
      // ignore - callbacks will receive errors where appropriate
    }
  }
}

async function runMigrationIfNeeded(config) {
  try {
    // Try to connect to the target database to ensure it exists
    const testConn = await mysqlPromise.createConnection({
      host: config.host,
      user: config.user,
      password: config.password,
      database: config.database,
      multipleStatements: true
    });
    await testConn.end();
    return;
  } catch (err) {
    console.warn('Database missing or inaccessible, attempting migration:', err.message);
    // Read SQL file and execute it using a connection without database selected
    const sqlPath = path.join(__dirname, 'smart_parking_db.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    const tmpConn = await mysqlPromise.createConnection({
      host: config.host,
      user: config.user,
      password: config.password,
      multipleStatements: true
    });
    try {
      await tmpConn.query(sql);
      console.log('Executed migration from smart_parking_db.sql');
    } finally {
      await tmpConn.end();
    }
  }
}

// Initialize pool asynchronously but export a wrapper immediately
(async function init() {
  try {
    await runMigrationIfNeeded(DEFAULTS);

    realPool = mysql.createPool(DEFAULTS);
    ready = true;
    flushPending();
  } catch (err) {
    initError = err;
    console.error('Database initialization failed:', err.message);
    // Still create a pool (calls will error) to keep API stable
    try {
      realPool = mysql.createPool(DEFAULTS);
      ready = true;
      flushPending();
    } catch (e) {
      // nothing
    }
  }
})();

// Wrapper exposes common methods used in the codebase and queues calls until ready.
const db = {
  query: function () {
    const args = Array.from(arguments);
    if (initError) {
      // If initialization errored, call callback with error if provided, otherwise return rejected promise
      const cb = args[args.length - 1];
      if (typeof cb === 'function') return cb(initError);
      return Promise.reject(initError);
    }
    if (!ready) {
      // queue this call
      pending.push({ method: 'query', args });
      return;
    }
    return realPool.query.apply(realPool, args);
  },
  execute: function () {
    const args = Array.from(arguments);
    if (!ready) {
      pending.push({ method: 'execute', args });
      return;
    }
    return realPool.execute.apply(realPool, args);
  },
  beginTransaction: function (cb) {
    if (!ready) {
      pending.push({ method: 'beginTransaction', args: [cb] });
      return;
    }
    realPool.getConnection((err, conn) => {
      if (err) return cb(err);
      conn.beginTransaction(cb);
      // release is caller's responsibility after commit/rollback
    });
  },
  commit: function (conn, cb) {
    if (!ready) return cb && cb(new Error('DB not ready'));
    conn.commit(err => {
      if (err) return conn.rollback(() => cb(err));
      conn.release();
      cb && cb(null);
    });
  },
  rollback: function (conn, cb) {
    if (!ready) return cb && cb(new Error('DB not ready'));
    conn.rollback(() => {
      conn.release();
      cb && cb(null);
    });
  },
  // expose getConnection for advanced uses
  getConnection: function (cb) {
    if (!ready) {
      pending.push({ method: 'getConnection', args: [cb] });
      return;
    }
    realPool.getConnection(cb);
  }
};

module.exports = db;