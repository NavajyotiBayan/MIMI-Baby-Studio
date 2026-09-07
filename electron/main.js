const { app, BrowserWindow, Menu, shell, dialog, ipcMain, Notification } = require('electron');
const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const http = require('http');

const PORT = Number(process.env.MIMI_PORT || 5000);
let mainWindow = null;
let backend = null;
let backendLog = null;

// Keep the Windows app chrome simple and avoid the default Electron menu.
Menu.setApplicationMenu(null);

function projectRoot() {
  return app.isPackaged ? path.join(process.resourcesPath, 'app.asar.unpacked') : path.resolve(__dirname, '..');
}
function runtimeRoot() {
  return app.isPackaged ? path.join(process.resourcesPath, 'runtime') : path.join(projectRoot(), 'runtime');
}
function dataRoot() { return path.join(app.getPath('userData'), 'data'); }
function logPath() { return path.join(app.getPath('userData'), 'mimi-backend.log'); }

function findPython() {
  const packagedPython = app.isPackaged ? path.join(runtimeRoot(), 'python', 'python.exe') : null;
  if (packagedPython && fs.existsSync(packagedPython)) return { command: packagedPython, prefix: [] };
  const candidates = [
    process.env.MIMI_PYTHON,
    packagedPython,
    path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Python', 'Python313', 'python.exe'),
    path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Python', 'Python312', 'python.exe'),
    path.join(process.env.ProgramFiles || 'C:\\Program Files', 'Python313', 'python.exe'),
    path.join(process.env.ProgramFiles || 'C:\\Program Files', 'Python312', 'python.exe'),
    'python.exe'
  ].filter(Boolean);
  for (const candidate of candidates) {
    try {
      const r = spawnSync(candidate, ['--version'], { stdio: 'ignore', windowsHide: true });
      if (!r.error && r.status === 0) return { command: candidate, prefix: [] };
    } catch (_) {}
  }
  try {
    const r = spawnSync('py.exe', ['-3.13', '--version'], { stdio: 'ignore', windowsHide: true });
    if (!r.error && r.status === 0) return { command: 'py.exe', prefix: ['-3.13'] };
  } catch (_) {}
  try {
    const r = spawnSync('py.exe', ['-3', '--version'], { stdio: 'ignore', windowsHide: true });
    if (!r.error && r.status === 0) return { command: 'py.exe', prefix: ['-3'] };
  } catch (_) {}
  return null;
}


function safeFileName(name, fallback = 'MIMI-Baby-Studio.pdf') {
  const cleaned = String(name || fallback).replace(/[<>:"/\\|?*\x00-\x1F]/g, '_').trim();
  return cleaned || fallback;
}

function isLocalDownloadUrl(value) {
  try {
    const u = new URL(value, `http://127.0.0.1:${PORT}`);
    return u.protocol === 'http:' && u.hostname === '127.0.0.1' && Number(u.port || 80) === PORT && u.pathname.startsWith('/download/');
  } catch (_) { return false; }
}

async function fetchPdf(url, filePath) {
  if (!isLocalDownloadUrl(url)) throw new Error('Invalid MIMI PDF download URL.');
  // Browser links are relative (/download/...), while Node/Electron fetch()
  // requires an absolute URL. Resolve the local Flask route before fetching.
  const resolvedUrl = new URL(url, `http://127.0.0.1:${PORT}`).toString();
  const response = await fetch(resolvedUrl);
  if (!response.ok) throw new Error(`Could not retrieve the PDF (HTTP ${response.status}).`);
  const buffer = Buffer.from(await response.arrayBuffer());
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, buffer);
  return filePath;
}

ipcMain.handle('mimi:open-pdf', async (_event, { url, fileName } = {}) => {
  const name = safeFileName(fileName);
  const dir = path.join(app.getPath('temp'), 'MIMI Baby Studio', 'PDF Preview');
  const target = path.join(dir, name);
  await fetchPdf(url, target);
  const error = await shell.openPath(target);
  if (error) throw new Error(error);
  return { ok: true, path: target };
});

ipcMain.handle('mimi:save-pdf', async (_event, { url, fileName } = {}) => {
  const name = safeFileName(fileName);
  const result = await dialog.showSaveDialog({
    title: 'Save PDF',
    defaultPath: path.join(app.getPath('downloads'), name),
    filters: [{ name: 'PDF document', extensions: ['pdf'] }],
    properties: ['createDirectory', 'showOverwriteConfirmation']
  });
  if (result.canceled || !result.filePath) return { canceled: true };
  await fetchPdf(url, result.filePath);
  if (Notification.isSupported()) {
    new Notification({ title: 'MIMI Baby Studio', body: `${path.basename(result.filePath)} saved successfully.` }).show();
  }
  return { ok: true, path: result.filePath };
});

ipcMain.handle('mimi:open-folder', async (_event, folderPath) => {
  const target = folderPath || path.join(app.getPath('temp'), 'MIMI Baby Studio', 'PDF Preview');
  fs.mkdirSync(target, { recursive: true });
  const error = await shell.openPath(target);
  if (error) throw new Error(error);
  return { ok: true, path: target };
});

function startBackend() {
  const python = findPython();
  if (!python) throw new Error('The bundled Python runtime was not found. Reinstall MIMI Baby Studio.');
  const backendScript = path.join(projectRoot(), 'app.py');
  if (!fs.existsSync(backendScript)) throw new Error(`MIMI backend was not found: ${backendScript}`);
  fs.mkdirSync(path.dirname(logPath()), { recursive: true });
  fs.mkdirSync(dataRoot(), { recursive: true });
  backendLog = fs.createWriteStream(logPath(), { flags: 'a' });
  backendLog.write(`\n=== MIMI Electron start ${new Date().toISOString()} ===\n`);
  backend = spawn(python.command, [...python.prefix, backendScript], {
    cwd: projectRoot(),
    env: {
      ...process.env,
      MIMI_PORT: String(PORT),
      MIMI_RUNTIME_DIR: runtimeRoot(),
      MIMI_DATA_DIR: dataRoot(),
      PYTHONUNBUFFERED: '1'
    },
    stdio: ['ignore', 'pipe', 'pipe'],
    windowsHide: true
  });
  backend.stdout.pipe(backendLog);
  backend.stderr.pipe(backendLog);
  backend.on('error', err => backendLog.write(`\n[backend error] ${err.stack || err}\n`));
  backend.on('exit', (code, signal) => backendLog.write(`\n[backend exit] code=${code} signal=${signal}\n`));
}

function waitForBackend(timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const started = Date.now();
    const check = () => {
      const req = http.get(`http://127.0.0.1:${PORT}/health`, res => {
        res.resume();
        if (res.statusCode === 200) return resolve();
        retry();
      });
      req.on('error', retry);
      req.setTimeout(1000, () => { req.destroy(); retry(); });
    };
    const retry = () => {
      if (Date.now() - started > timeoutMs) return reject(new Error(`MIMI backend did not start on port ${PORT}. See log: ${logPath()}`));
      setTimeout(check, 250);
    };
    check();
  });
}

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280, height: 820, minWidth: 1000, minHeight: 700,
    show: true, backgroundColor: '#f7f8f3',
    autoHideMenuBar: true,
    icon: path.join(__dirname, 'mimi-baby-studio.ico'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true, nodeIntegration: false, sandbox: true
    }
  });
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  // Use an embedded logo image in the splash screen. This avoids file:// /
  // app.asar-unpacked path issues that can make the splash logo appear broken.
  const splashLogoPath = path.join(projectRoot(), 'static', 'mimi-logo-256.png');
  let splashLogo = '';
  try {
    splashLogo = `data:image/png;base64,${fs.readFileSync(splashLogoPath).toString('base64')}`;
  } catch (_) {
    splashLogo = '';
  }
  const logoMarkup = splashLogo
    ? `<img class=\"logo\" src=\"${splashLogo}\" alt=\"MIMI Baby Studio\">`
    : `<div class=\"logo-fallback\">M</div>`;
  const splashHtml = `<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>MIMI Baby Studio</title><style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#f7f8f3;font-family:Segoe UI,system-ui,sans-serif;color:#4d4550}body{display:grid;place-items:center}.box{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}.logo,.logo-fallback{width:82px;height:82px;border-radius:22px;display:block;object-fit:cover;box-shadow:0 10px 28px rgba(90,62,112,.14)}.logo-fallback{display:grid;place-items:center;background:#eef3ea;color:#789477;font-size:34px;font-weight:800}.title{margin-top:16px;font-weight:700;font-size:18px;line-height:1.2}.sub{margin-top:6px;font-size:10px;color:#958b97;letter-spacing:1.4px}</style></head><body><div class=\"box\">${logoMarkup}<div class=\"title\">MIMI Baby Studio</div><div class=\"sub\">STARTING LOCALLY…</div></div></body></html>`;
  await mainWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(splashHtml)}`);
}

async function boot() {
  try {
    // Start the local backend immediately while Chromium creates the window.
    // This overlaps the two startup costs instead of doing them sequentially.
    startBackend();
    await createWindow();
    await waitForBackend();
    if (mainWindow && !mainWindow.isDestroyed()) await mainWindow.loadURL(`http://127.0.0.1:${PORT}/`);
  } catch (err) {
    const message = err?.message || String(err);
    console.error(message);
    try { fs.mkdirSync(path.dirname(logPath()), { recursive: true }); fs.appendFileSync(logPath(), `\n[BOOT ERROR] ${message}\n`); } catch (_) {}
    await dialog.showMessageBox({ type: 'error', title: 'MIMI Baby Studio', message: 'MIMI Baby Studio could not start.', detail: `${message}\n\nLog: ${logPath()}` });
    app.exit(1);
  }
}

app.whenReady().then(boot);
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
app.on('before-quit', () => {
  if (backend && !backend.killed) { try { backend.kill(); } catch (_) {} }
  try { backendLog?.end(); } catch (_) {}
});
