# convert_dv7_to_dv81.bat

Windows batch script designed to convert **Dolby Vision Profile 7 (DV7)** video files into **Dolby Vision Profile 8.1 (DV8.1)**, which is more widely supported by TVs, media players, and streaming platforms such as Plex.

The script focuses on improving playback compatibility while preserving video quality and Dolby Vision metadata as much as possible.

---

## Features

- Detects Dolby Vision Profile 7 streams
- Converts DV Profile 7 to **Dolby Vision Profile 8.1**
- Preserves:
  - HDR base layer
  - Dolby Vision metadata
  - Video and audio streams
- Designed for MKV files
- Fully automated batch processing
- Detailed logging

---

## Folder Structure

- `convert_dv7_to_dv81.bat`
- `input`
- `output`
- `tools`
- `temp`
- `logs`

---

## Requirements

### Operating System

- Windows (64-bit)

### External Tools (mandatory)

Extract **only the required binaries** from each archive and place them in the `tools` folder.

---

### FFmpeg

Used for demuxing, remuxing, and video stream handling.

Required files:
- `ffmpeg.exe`
- `ffprobe.exe`

Download:
- https://www.gyan.dev/ffmpeg/builds/#release-builds  
- Archive: `ffmpeg-release-full.7z`  
- Direct link: https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-full.7z

---

### MKVToolNix

Used for extracting and remuxing MKV streams.

Required files:
- `mkvmerge.exe`
- `mkvextract.exe`

Download:
- https://mkvtoolnix.download/downloads.html#windows  
- Portable 64-bit version (`.7z`)

---

### dovi_tool

Used to parse, convert, and rebuild Dolby Vision metadata.

Required file:
- `dovi_tool.exe`

Download:
- https://github.com/quietvoid/dovi_tool/releases/latest  
- Asset: Windows x64 (`dovi_tool-X.X.X-x86_64-pc-windows-msvc.zip`)

---

## Usage

1. Place MKV files in the `input` folder  
2. Run the script: `convert_dv7_to_dv81.bat`  
3. Converted files will be written to the `output` folder  

Files without Dolby Vision Profile 7 metadata are skipped automatically.

---

## Important Notes

- Do not place the script in a path containing spaces
- Save the script as **UTF-8 with BOM (UTF-8-BOM)**  
  (required for correct handling of special characters)
- Always test on a sample file before batch processing
- The script is designed for **MKV input only**
- Dolby Vision compatibility depends on the target playback device

---

## Logging

Each run generates a detailed log file:

- `logs/log_dv_conversion.txt`

The log includes:
- detected Dolby Vision profiles
- metadata extraction and conversion steps
- remuxing commands
- errors, if any

---

## Limitations

- Designed specifically for Dolby Vision Profile 7 → Profile 8.1
- Not all DV7 files can be converted without feature loss
- Playback compatibility varies depending on the device
- Intended for personal and experimental use
- No GUI

---

## Credits

This script was created, refined, and improved with the assistance of **ChatGPT** and **Claude**, used as technical assistants for:
- understanding Dolby Vision profiles
- metadata processing workflows
- batch scripting logic
- command optimization and robustness

Final testing, validation, and usage decisions were performed manually.

---

## License

MIT License  
See the `LICENSE` file for details.
