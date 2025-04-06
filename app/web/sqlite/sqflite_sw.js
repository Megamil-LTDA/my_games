importScripts("sqlite3.js");

const db = {
  1: new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', 'sqlite/sqlite3.js', true);
    xhr.onload = () => {
      if (xhr.status === 200) {
        resolve();
      } else {
        reject(`Failed to load sqlite3.js: ${xhr.status}`);
      }
    };
    xhr.onerror = () => reject('Failed to load sqlite3.js');
    xhr.send();
  }),
};

const dbNameMap = {};

function log(message) {
  console.log(`[sqflite_sw.js] ${message}`);
}

function getDBFromPath(path) {
  return dbNameMap[path];
}

function openDB(index, path, readOnly, singleInstance) {
  const config = {
    filename: path,
    memory: path === ':memory:',
  };
  const db = new SQL.Database(config);
  dbNameMap[path] = db;
  log(`Opened database at ${path} (readOnly: ${readOnly}, singleInstance: ${singleInstance})`);
  return db;
}

function closeDB(index, path) {
  const db = getDBFromPath(path);
  if (db) {
    db.close();
    delete dbNameMap[path];
    log(`Closed database at ${path}`);
  }
}

function executeSQL(index, path, sql, params) {
  const db = getDBFromPath(path);
  if (!db) {
    throw new Error(`Database not found for path: ${path}`);
  }
  try {
    const result = db.exec(sql, params);
    log(`Executed SQL: ${sql} with params: ${JSON.stringify(params)}`);
    return { rows: result };
  } catch (e) {
    log(`Error executing SQL: ${e.message}`);
    throw e;
  }
}

function batch(index, path, operations) {
  const db = getDBFromPath(path);
  if (!db) {
    throw new Error(`Database not found for path: ${path}`);
  }
  try {
    const results = [];
    db.exec('BEGIN TRANSACTION');
    operations.forEach(op => {
      const { sql, params } = op;
      const result = db.exec(sql, params);
      results.push(result);
    });
    db.exec('COMMIT');
    log(`Executed batch of ${operations.length} operations`);
    return results;
  } catch (e) {
    db.exec('ROLLBACK');
    log(`Error executing batch: ${e.message}`);
    throw e;
  }
}

function handleDatabaseCall(call) {
  const { method, arguments } = call;
  const { id } = call;
  try {
    switch (method) {
      case 'openDatabase':
        const { path, readOnly, singleInstance } = arguments;
        const db = openDB(id, path, readOnly, singleInstance);
        return { result: true };
      
      case 'closeDatabase':
        const { path: closePath } = arguments;
        closeDB(id, closePath);
        return { result: true };
      
      case 'execute':
        const { sql, arguments: sqlArgs, path: execPath } = arguments;
        const execResult = executeSQL(id, execPath, sql, sqlArgs);
        return { result: execResult };
      
      case 'batch':
        const { operations, path: batchPath } = arguments;
        const batchResult = batch(id, batchPath, operations);
        return { result: batchResult };
      
      default:
        throw new Error(`Unsupported method: ${method}`);
    }
  } catch (e) {
    return { error: e.message };
  }
}

self.addEventListener('message', (event) => {
  const call = event.data;
  Promise.resolve(db[1]).then(() => {
    const response = handleDatabaseCall(call);
    self.postMessage({ ...response, id: call.id });
  }).catch((error) => {
    self.postMessage({ error: error.toString(), id: call.id });
  });
});

log('SQLite service worker initialized'); 