const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('mimiDesktop', Object.freeze({
  isElectron: true,
  openPdf: (url, fileName) => ipcRenderer.invoke('mimi:open-pdf', { url, fileName }),
  savePdf: (url, fileName) => ipcRenderer.invoke('mimi:save-pdf', { url, fileName }),
  openPdfFolder: () => ipcRenderer.invoke('mimi:open-folder')
}));
