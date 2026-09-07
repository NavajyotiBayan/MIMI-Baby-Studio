# MIMI Baby Studio v2.0.0

**MIMI Baby Studio** is a private Windows desktop app for converting videos and images into PDF documents.

> **100% local processing.** Your media stays on your computer.

## Features

- 🎬 Video → PDF with FFmpeg frame extraction
- 🖼️ Images → PDF
- 📐 Page size, orientation, margins and image-fit controls
- 🎞️ Adjustable frame interval and frames per page
- 🕒 Optional timestamps
- 📊 Conversion progress
- 📚 Persistent local conversion history
- 🎨 MIMI Baby Studio themes, music and stickers
- 📄 Native Windows PDF open/save actions
- 📁 Native output-folder opening
- 🔒 No cloud account required for conversion

## Windows installation

### Recommended — one command

```powershell
irm mimibaby.navajyoti.online | iex
```

The installer checks the latest GitHub Release, downloads the signed/published Windows Setup executable, and launches the normal Windows installer.

### Manual

Download **MIMI-Baby-Studio-2.0.0-Setup.exe** from the GitHub Releases page.

A **Portable.exe** build is also published for users who do not want a normal installation.

## GitHub Releases

Tagged releases are built automatically by GitHub Actions. The workflow produces both Setup and Portable Windows packages plus SHA-256 checksums.

## Performance

The desktop UI is optimized for low idle CPU/GPU usage while keeping MIMI's visual design and local processing workflow. Continuous decorative animations and unnecessary startup network requests are disabled.

## Privacy

Conversions run locally using the bundled Flask/Pillow/FFmpeg runtime. Generated PDFs and conversion history are stored in the application's Windows user-data directory.

## Open Source Credits & Licenses

MIMI Baby Studio is built with and distributes the following open-source software:

| Project | Purpose | License |
|---|---|---|
| **Electron** | Windows desktop application framework | MIT |
| **Python** | Embedded application runtime | Python Software Foundation License 2.0 |
| **Flask** | Local application backend | BSD-3-Clause |
| **Pillow** | Image processing and PDF generation | HPND / PIL Software License |
| **FFmpeg** | Video decoding and frame extraction | GPL (for the selected GPL build/components) |
| **BtbN FFmpeg Builds** | Windows FFmpeg distribution | GPL / applicable FFmpeg licensing |

We are grateful to the developers and maintainers of these open-source projects. Their licenses remain applicable to the respective components distributed with MIMI Baby Studio.

For detailed third-party notices, upstream project links, and licensing information, see `THIRD-PARTY-NOTICES.md`.

## License

MIMI Baby Studio source code is released under the MIT License. See `LICENSE` and `THIRD-PARTY-NOTICES.md` for dependency/runtime notices.
