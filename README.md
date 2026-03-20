# FileSync - Wireless File Manager for KOReader

A KOReader plugin that launches a local web server on your e-reader and displays a QR code on screen. Scan the code with your phone to open a polished web interface for managing books and files wirelessly — no cables, no apps, just your browser.

Works on **Kindle** and **Kobo** devices running KOReader.

## Features

- **QR Code Access** — Scan to connect instantly, no typing URLs
- **File Browser** — Navigate your library with breadcrumb navigation
- **Upload Files** — Drag-and-drop or tap to upload books from your phone
- **Download Files** — Save any file to your phone with one tap
- **Create Folders** — Organize your library into directories
- **Rename & Delete** — Full file management with confirmation dialogs
- **Search & Sort** — Filter by name, sort by name/size/date/type
- **Responsive UI** — Designed for smartphones, works on any screen
- **Zero Dependencies** — Pure Lua server, self-contained HTML interface
- **Secure** — Path traversal protection, input sanitization, local network only

## How It Works

1. Connect your e-reader to WiFi
2. Open the FileSync plugin from KOReader's Tools menu
3. A QR code appears on the e-reader screen
4. Scan it with your phone (connected to the same WiFi)
5. Manage your books from the web interface in your phone's browser

## Installation

### Prerequisites

- A Kindle or Kobo e-reader with [KOReader](https://github.com/koreader/koreader) installed
- Both your e-reader and phone on the same WiFi network

### Option 1: Direct Copy (Recommended)

1. Connect your e-reader to your computer via USB

2. Locate the KOReader plugins directory:
   - **Kindle:** `/mnt/us/koreader/plugins/`
   - **Kobo:** `.adds/koreader/plugins/` (on the root of the SD card)

3. Copy the entire `FileSync.koplugin` folder into the plugins directory:
   ```
   plugins/
   ├── FileSync.koplugin/
   │   ├── _meta.lua
   │   ├── main.lua
   │   ├── filesyncmanager.lua
   │   ├── httpserver.lua
   │   ├── fileops.lua
   │   ├── qrcode.lua
   │   └── static/
   │       └── index.html
   ├── other.koplugin/
   └── ...
   ```

4. Safely eject and restart KOReader

### Option 2: From Release Archive

1. Download the latest release `.zip` from the [Releases](../../releases) page
2. Extract the archive
3. Copy the `FileSync.koplugin` folder to your device's KOReader plugins directory (see paths above)
4. Restart KOReader

### Building from Source

Clone the repository and package the plugin:

```bash
git clone https://github.com/yourusername/FileSync.koplugin.git
cd FileSync.koplugin

# Create a distributable archive (exclude dev files)
mkdir -p dist
zip -r dist/FileSync.koplugin.zip \
  _meta.lua \
  main.lua \
  filesyncmanager.lua \
  httpserver.lua \
  fileops.lua \
  qrcode.lua \
  static/index.html
```

Then copy `dist/FileSync.koplugin.zip` to your device, extract it into the plugins directory, and restart KOReader.

### Verifying Installation

After restarting KOReader, open the top menu and navigate to:

**Network → FileSync - Wireless File Manager**

If you see the menu entry, the plugin is installed correctly.

## Usage

### Starting the Server

1. Open KOReader's top menu
2. Navigate to **Network → FileSync - Wireless File Manager**
3. Tap **Start file server**
4. A QR code will appear on screen with the connection URL

### Connecting from Your Phone

1. Make sure your phone is on the **same WiFi network** as the e-reader
2. Open your phone's camera and scan the QR code
3. Tap the link to open the web interface in your browser
4. Alternatively, type the URL shown below the QR code manually

### Managing Files

| Action | How |
|--------|-----|
| **Browse** | Tap folders to navigate, use breadcrumbs to go back |
| **Upload** | Tap the upload button or drag files onto the drop zone |
| **Download** | Tap the download icon on any file |
| **New Folder** | Tap the folder+ button in the header |
| **Rename** | Tap the pencil icon on any file or folder |
| **Delete** | Tap the trash icon (confirmation required) |
| **Search** | Type in the search bar to filter files by name |
| **Sort** | Use the sort dropdown to change ordering |

### Stopping the Server

- Tap **Stop file server** from the plugin menu, or
- The server stops automatically when the device suspends and restarts on wake

### Changing the Port

1. Open the plugin menu
2. Tap **Server port**
3. Enter a port number between 1024 and 65535 (default: 8080)
4. Restart the server for the change to take effect

## Configuration

| Setting | Default | Range | Persisted |
|---------|---------|-------|-----------|
| Server port | `8080` | 1024–65535 | Yes |

Settings are stored in KOReader's configuration and persist across restarts.

## Device Storage Paths

The plugin automatically detects the correct root directory for file operations:

| Device | Root Path |
|--------|-----------|
| Kindle | `/mnt/us` |
| Kobo | `/mnt/onboard` |
| PocketBook | `/mnt/ext1` |
| Android | External storage |

## API Reference

The plugin exposes a REST-like HTTP API for programmatic access:

| Endpoint | Method | Parameters | Description |
|----------|--------|------------|-------------|
| `/api/files` | GET | `path`, `sort`, `order`, `filter` | List directory contents |
| `/api/download` | GET | `path` | Download a file |
| `/api/upload` | POST | `path` (query), multipart body | Upload files |
| `/api/mkdir` | POST | `{"path": "/new/folder"}` | Create directory |
| `/api/rename` | POST | `{"old_path": "/a", "new_path": "/b"}` | Rename file/folder |
| `/api/delete` | POST | `{"path": "/file/to/delete"}` | Delete file/folder |

### Example: List Files

```bash
curl http://<device-ip>:8080/api/files?path=/&sort=name&order=asc
```

### Example: Upload a Book

```bash
curl -F "file=@mybook.epub" http://<device-ip>:8080/api/upload?path=/Books
```

## Security

- **Local network only** — The server binds to the device's local IP, not accessible from the internet
- **Path traversal protection** — All paths are validated to stay within the device's storage root
- **Input sanitization** — Filenames are validated for null bytes, path separators, and length limits
- **Kindle firewall** — Automatically opens/closes the required port via iptables on Kindle devices
- **No authentication** — Since this runs on a trusted local network, no auth is required. Do not expose the port to the internet.

## Architecture

```
FileSync.koplugin/
├── _meta.lua              Plugin metadata (name, description)
├── main.lua               Entry point, menu registration, lifecycle hooks
├── filesyncmanager.lua    Server orchestration, WiFi/IP detection, QR display
├── httpserver.lua         Non-blocking HTTP/1.1 server (LuaSocket)
├── fileops.lua            File CRUD operations with security validation
├── qrcode.lua             QR code generation fallback module
└── static/
    └── index.html         Self-contained web UI (HTML + CSS + JS)
```

### Key Design Decisions

- **Non-blocking server** — Uses `UIManager:scheduleIn()` to poll for connections without freezing the KOReader UI
- **Single-file web UI** — All CSS and JS are inlined in `index.html` to avoid multiple HTTP requests and external dependencies
- **Pure Lua** — No compiled binaries or external tools required, ensuring compatibility across all KOReader-supported devices
- **Suspend-aware** — Server automatically stops on device suspend and restarts on wake to conserve battery

## Troubleshooting

**Plugin doesn't appear in the menu**
- Ensure the folder is named exactly `FileSync.koplugin` (case-sensitive)
- Check that `_meta.lua` and `main.lua` are directly inside the folder (not nested)
- Restart KOReader completely

**"WiFi is not enabled" error**
- Connect your e-reader to a WiFi network before starting the server
- Some devices require WiFi to be explicitly enabled in KOReader's network settings

**Phone can't connect**
- Verify both devices are on the same WiFi network
- Try typing the URL manually instead of scanning the QR code
- Check if your router has client isolation enabled (prevents devices from seeing each other)
- On Kindle: the plugin manages firewall rules automatically, but a restart may help if rules are stuck

**Upload fails**
- Check available storage space on the device
- Very large files may time out — try uploading smaller batches
- Ensure the target directory is writable

## Contributing

Contributions are welcome! This plugin lives outside the official KOReader repository (upstream considers HTTP file servers out of scope).

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a real device if possible
5. Submit a pull request

## License

This project is licensed under the [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.html), consistent with the KOReader project.
