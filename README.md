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

## How It Works

1. Connect your e-reader to WiFi
2. Open the FileSync plugin from KOReader's Network Tools menu
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
   │   └── filesync/
   │       ├── filesyncmanager.lua
   │       ├── httpserver.lua
   │       ├── fileops.lua
   │       ├── filesync_i18n.lua
   │       ├── qrcode.lua
   │       ├── static/
   │       │   └── index.html
   │       └── i18n/
   │           ├── en.po
   │           └── es.po
   ├── other.koplugin/
   └── ...
   ```

4. Safely eject and restart KOReader

### Option 2: From Release Archive

1. Download the latest release `.zip` from the [Releases](../../releases) page
2. Extract the archive
3. Copy the `FileSync.koplugin` folder to your device's KOReader plugins directory (see paths above)
4. Restart KOReader

### Verifying Installation

After restarting KOReader, open the top menu and navigate to:

**Network → FileSync**

If you see the menu entry, the plugin is installed correctly.

## Usage

### Starting the Server

0. Make sure you're device is connected to WiFi
1. Open KOReader's top menu
2. Navigate to **Network → FileSync**
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

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on a real device if possible
5. Submit a pull request

## License

This project is licensed under the [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.html), consistent with the KOReader project.
