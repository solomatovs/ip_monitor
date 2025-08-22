# IP Monitor

A powerful network connection monitoring tool that tracks IP addresses and network activity for specific processes and their descendants using DTrace on macOS.

## Features

- 🔍 **Process Tracking**: Monitor specific processes by PID and automatically track all their child processes
- 🌐 **Network Monitoring**: Capture IPv4/IPv6 connections, socket operations, and data transfers
- 📊 **Real-time Analysis**: View network activity in real-time or save to log files
- 🎯 **Targeted Monitoring**: Focus on specific applications like Chrome, Firefox, Yandex, or any process
- 📈 **Statistics**: Get periodic summaries and connection counts
- 🔧 **Easy Setup**: Simple Makefile for common monitoring tasks

## Requirements

- macOS with DTrace support
- sudo/root privileges (required for DTrace)
- Bash shell

## Installation

1. Clone or download the script files
2. Make the script executable and set up directories:
   ```bash
   make setup
   ```

## Usage

### Quick Start with Makefile

The easiest way to use the IP monitor is through the provided Makefile:

```bash
# Monitor Chrome processes
make chrome

# Monitor Firefox processes
make firefox

# Monitor Yandex processes
make yandex

# Monitor a specific PID
make pid PID=1234,3453,222

# Monitor any process by name
make app PROC=node

# Show available processes
make show PROC=chrome

# See all available options
make help
```

### Direct Script Usage

You can also run the script directly for more control:

```bash
# Monitor specific PIDs
sudo ./ip_monitor.sh 1234,5678

# Save output to file
sudo ./ip_monitor.sh --output my_log.txt 1234,5678

# Enable verbose output
sudo ./ip_monitor.sh --verbose $(pgrep Chrome | tr '\n' ',')

# Keep the generated DTrace script
sudo ./ip_monitor.sh --keep-script 1234
```

### Script Options

- `--output FILE`: Specify output file name (default: timestamped file)
- `--keep-script`: Don't delete the generated DTrace script after execution
- `--help`: Show usage information

## What It Monitors

### Network Activity
- **Socket Creation**: AF_INET, AF_INET6, AF_UNIX socket creation
- **Connections**: TCP/UDP connection attempts with IP addresses and ports
- **Data Transfer**: Read/write operations on network file descriptors
- **Socket Management**: Socket closing and cleanup

### Process Activity  
- **Process Creation**: New child processes spawned by monitored processes
- **Process Termination**: When monitored processes or their children exit

### Output Information
- IPv4/IPv6 addresses and ports for outbound connections
- Socket types (TCP/UDP) and protocols
- Data transfer volumes (bytes read/written)
- Process hierarchy (parent/child relationships)
- Connection success/failure status

## Example Output

```
solomatovs:ip_monitor solomatovs$ make yandex
Setting up IP Monitor...
✅ Setup complete. Logs will be saved to ./logs/
🔍 Looking for Yandex processes...
/Applications/Xcode.app/Contents/Developer/usr/bin/make app PROC=yandex
Setting up IP Monitor...
✅ Setup complete. Logs will be saved to ./logs/
🔍 Looking for yandex processes...
📡 Monitoring yandex PIDs: 724,833,1634,1706,1707,1726,1729,3847,8725,21805,21806,42994,49765,49821,50730,53421,53521,65193,65915,74679
Password:
Sorry, try again.
Password:
=== Checking root PIDs ===
✅ Root PID 724: /Applications/Yandex.app/Contents/MacOS/Yandex
✅ Root PID 833: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (GPU).app/Contents/MacOS/Yandex Helper (GPU)
✅ Root PID 1634: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper.app/Contents/MacOS/Yandex Helper
✅ Root PID 1706: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 1707: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 1726: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper.app/Contents/MacOS/Yandex Helper
✅ Root PID 1729: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 3847: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper.app/Contents/MacOS/Yandex Helper
✅ Root PID 8725: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 21805: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper.app/Contents/MacOS/Yandex Helper
✅ Root PID 21806: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Plugin).app/Contents/MacOS/Yandex Helper (Plugin)
✅ Root PID 42994: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 49765: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 49821: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 50730: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 53421: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 53521: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 65193: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 65915: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
✅ Root PID 74679: /Applications/Yandex.app/Contents/Frameworks/Yandex Framework.framework/Versions/25.6.3.358/Helpers/Yandex Helper (Renderer).app/Contents/MacOS/Yandex Helper (Renderer)
=== Monitoring settings ===
Root PIDs: 724 833 1634 1706 1707 1726 1729 3847 8725 21805 21806 42994 49765 49821 50730 53421 53521 65193 65915 74679
Output file: ./logs/20250822_183909.log
==============================

Starting monitoring of root PIDs and their descendants...
Press Ctrl+C to stop

dtrace: script 'generated_ips_monitor_$.d' matched 176 probes
^C
=== Results ===
📄 File: ./logs/20250822_183909.log
📊 Lines:     1608

🎯 IP connections:
  36 IPv4: 192.168.90.1:53
   3 IPv4: 213.180.193.234:443
   3 IPv4: 173.194.221.101:443
   2 IPv4: 87.250.254.106:443
   2 IPv4: 64.233.164.94:443
   2 IPv4: 64.233.164.103:443
   2 IPv4: 213.180.204.232:443
   2 IPv4: 173.194.221.157:443
   1 IPv4: 87.250.251.183:443
   1 IPv4: 74.125.205.95:443
   1 IPv4: 64.233.165.102:443
   1 IPv4: 64.233.161.94:443
   1 IPv4: 5.255.255.77:443
   1 IPv4: 192.168.90.6:9832
   1 IPv4: 192.168.90.6:8794
   1 IPv4: 192.168.90.6:63553
   1 IPv4: 192.168.90.6:62976
   1 IPv4: 192.168.90.6:62571
   1 IPv4: 192.168.90.6:61758
   1 IPv4: 192.168.90.6:60819
   1 IPv4: 192.168.90.6:57472
   1 IPv4: 192.168.90.6:57287
   1 IPv4: 192.168.90.6:57219
   1 IPv4: 192.168.90.6:57098
   1 IPv4: 192.168.90.6:54178
   1 IPv4: 192.168.90.6:52925
   1 IPv4: 192.168.90.6:52727
   1 IPv4: 192.168.90.6:52509
   1 IPv4: 192.168.90.6:52494
   1 IPv4: 192.168.90.6:47006
   1 IPv4: 192.168.90.6:45151
   1 IPv4: 192.168.90.6:41019
   1 IPv4: 192.168.90.6:40735
   1 IPv4: 192.168.90.6:38766
   1 IPv4: 192.168.90.6:37818
   1 IPv4: 192.168.90.6:35964
   1 IPv4: 192.168.90.6:34613
   1 IPv4: 192.168.90.6:34464
   1 IPv4: 192.168.90.6:33129
   1 IPv4: 192.168.90.6:32767
   1 IPv4: 192.168.90.6:31658
   1 IPv4: 192.168.90.6:31029
   1 IPv4: 192.168.90.6:3059
   1 IPv4: 192.168.90.6:30110
   1 IPv4: 192.168.90.6:28852
   1 IPv4: 192.168.90.6:27220
   1 IPv4: 192.168.90.6:16335
   1 IPv4: 192.168.90.6:14830
   1 IPv4: 192.168.90.6:14693
   1 IPv4: 192.168.90.6:14662
   1 IPv4: 192.168.90.6:14602
   1 IPv4: 192.168.90.6:14493
   1 IPv4: 192.168.90.6:12757
   1 IPv4: 192.168.90.6:12129
   1 IPv4: 192.168.90.6:10867
   1 IPv4: 185.180.200.2:443
   1 IPv4: 173.194.73.139:443
   1 IPv4: 173.194.221.94:443
   1 IPv4: 140.82.121.3:443
   1 IPv4: 140.82.114.21:443
   1 IPv4: 108.177.14.94:443

🎯 Mikrotik firewall list:
/ip firewall address-list
add address=108.177.14.94 list=vpn_traffik
add address=140.82.114.21 list=vpn_traffik
add address=140.82.121.3 list=vpn_traffik
add address=173.194.221.101 list=vpn_traffik
add address=173.194.221.157 list=vpn_traffik
add address=173.194.221.94 list=vpn_traffik
add address=173.194.73.139 list=vpn_traffik
add address=185.180.200.2 list=vpn_traffik
add address=192.168.90.1 list=vpn_traffik
add address=192.168.90.6 list=vpn_traffik
add address=213.180.193.234 list=vpn_traffik
add address=213.180.204.232 list=vpn_traffik
add address=5.255.255.77 list=vpn_traffik
add address=64.233.161.94 list=vpn_traffik
add address=64.233.164.103 list=vpn_traffik
add address=64.233.164.94 list=vpn_traffik
add address=64.233.165.102 list=vpn_traffik
add address=74.125.205.95 list=vpn_traffik
add address=87.250.251.183 list=vpn_traffik
add address=87.250.254.106 list=vpn_traffik

📋 Unique ips:       20
make: *** [yandex] Interrupt: 2
```

## Understanding the Output

- **🎯 IPv4/IPv6**: Actual IP addresses and ports being connected to
- **➕ NEW_DESCENDANT**: A new child process was created
- **➖ DESCENDANT_EXITED**: A child process terminated
- **SOCKET_SUCCESS/FAILED**: Socket creation results
- **CONNECT_SUCCESS/FAILED**: Connection attempt results
- **WRITE/READ**: Data being sent/received (shows file descriptor and byte count)

## Common Use Cases

### Monitor Web Browser Activity
```bash
make chrome
# or
make firefox
```

### Monitor Development Tools
```bash
make monitor-app PROC=node
make monitor-app PROC=python
```

### Security Auditing
```bash
# Monitor a suspicious process
make pid PID=suspicious_pid
```
## Log Files

logs are saved with timestamps:
- Default location: current directory
- Custom location: use `--output filename`
- Makefile logs: saved to `./logs/` directory

Log files include:
- Summary statistics (total connections, line count)
- Top IP addresses connected to
- New descendant processes created

## Troubleshooting

### Permission Issues
```bash
❌ sudo required
```
**Solution**: DTrace requires root privileges. Use `sudo` or run as root.

### No Processes Found
```bash
❌ No <proc> processes found
```
**Solution**: Check if the process is running:
```bash
make show PROC=chrome
# or
pgrep chrome
```

### DTrace Issues
If DTrace fails to start, ensure:
- You're on macOS (DTrace support varies on other systems)
- System Integrity Protection (SIP) isn't blocking DTrace
- No other DTrace sessions are running

## File Structure

```
.
├── ip_monitor.sh          # Main monitoring script
├── Makefile               # Easy-to-use commands
├── README.md              # This file
└── logs/                  # Log files (created by make setup)
    ├── *.log
    └── ...
```

## Security Considerations

- This tool requires root privileges to use DTrace
- It monitors network connections which may include sensitive data
- Log files may contain IP addresses and connection information
- Use responsibly and in compliance with your organization's policies

## Contributing

Feel free to submit issues and enhancement requests. When contributing:
1. Test your changes on macOS
2. Update documentation for new features
3. Follow the existing code style

## License

This tool is provided as-is for educational and debugging purposes. Use responsibly and ensure compliance with local laws and regulations regarding network monitoring.
