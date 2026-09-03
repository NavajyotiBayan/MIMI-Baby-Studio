# MIMI Baby Studio v2

A cute, private, local Windows productivity studio for converting videos and images into PDF documents.

> **100% local processing** — your files stay on your computer.

## ✨ Features

- 🎬 Video → PDF with FFmpeg frame extraction
- 🖼️ Images → PDF
- 📐 Page size, orientation, margins and image-fit controls
- 🎞️ Adjustable frame interval and frames per page
- 🕒 Optional timestamps
- 👀 Preview before conversion
- 📊 Conversion progress and FFmpeg console
- 📚 Local conversion history
- 🎨 Five eye-comfort themes
- 🎵 Built-in calm background music
- 💕 Cute animated stickers
- 🖥️ macOS-inspired interface
- 🔒 Runs locally on `127.0.0.1`

## 🚀 Quick Start

1. Download or clone this repository.
2. On Windows, double-click `start.bat`.
3. Allow Administrator access when Windows asks.
4. The studio automatically installs to:

   `C:\MIMI Baby Studio`

5. Required dependencies are installed automatically when needed.
6. Your browser opens automatically when the local server is ready.

### Requirements

- Windows 10/11
- Internet connection for first-time dependency installation
- Python 3.11+ (the installer can install Python automatically)
- FFmpeg (the installer can install it automatically)

## 🛠️ Included Windows Scripts

| File | Purpose |
|---|---|
| `start.bat` | Install/setup and launch the studio |
| `stop_server.bat` | Stop the local server |
| `debug_server.bat` | Run the server visibly for troubleshooting |
| `repair-dependencies.bat` | Repair Python dependencies |
| `uninstall-all-dependencies.bat` | Remove installed Python/FFmpeg dependencies |
| `launch_silent.vbs` | Start the Flask server without a console window |

## 🔐 Privacy

MIMI Baby Studio is designed for local processing. Uploaded media is processed by the local Flask application and FFmpeg/Pillow on your PC. The application does not require a cloud account to perform conversions.

The motivational quote feature may contact DummyJSON to retrieve a quote when available; a local fallback is used if it cannot connect.

## 📁 Project Structure

```text
MIMI-Baby-Studio/
├── app.py
├── start.bat
├── stop_server.bat
├── debug_server.bat
├── repair-dependencies.bat
├── uninstall-all-dependencies.bat
├── launch_silent.vbs
├── requirements.txt
├── templates/
│   └── index.html
└── static/
    ├── app.js
    ├── style.css
    ├── audio/
    │   └── mimi-soft-breeze.mp3
    └── stickers/
        ├── bunny-love.gif
        ├── cute-girl-love.gif
        ├── happy-in-love.gif
        ├── hungry-cat.gif
        └── miss-you.gif
```

## 💻 Development

To run the Flask application manually:

```powershell
python -m pip install -r requirements.txt
python app.py
```

Then open:

```text
http://127.0.0.1:5000
```

For normal users, `start.bat` is recommended because it handles installation, dependency setup, FFmpeg detection and silent launching.

## 🧹 Troubleshooting

If the browser does not open:

1. Run `start.bat` again.
2. Use `debug_server.bat` to see the server output.
3. Check `server.log` in the installed folder.
4. Use `repair-dependencies.bat` if Python packages are missing.

To completely remove the automatically installed dependencies, run `uninstall-all-dependencies.bat` as Administrator.

## 📜 License

This project is released under the MIT License. See [`LICENSE`](LICENSE).

## ❤️ MIMI Baby Studio

Made with love for a smoother workday. ♥
