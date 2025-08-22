# IP Monitor

A powerful network connection monitoring tool that tracks IP addresses and network activity for specific processes and their descendants using DTrace on macOS.

## Features

- 🔍 **Process Tracking**: Monitor specific processes by PID and automatically track all their child processes
- 🌐 **Network Monitoring**: Capture IPv4/IPv6 connections, socket operations, and data transfers
- 📊 **Real-time Analysis**: View network activity in real-time or save to log files
- 🎯 **Targeted Monitoring**: Focus on specific applications like Claude, Chrome, Firefox, or any process
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
# Monitor Claude processes in real-time
make monitor-claude

# Monitor Chrome processes in real-time  
make monitor-chrome

# Monitor Firefox processes in real-time
make monitor-firefox

# Monitor a specific PID
make monitor-pid PID=1234

# Monitor any process by name
make monitor-custom PROC=node

# Save Claude monitoring to log file
make log-claude

# Show available processes
make show-processes

# See all available options
make help
```

### Direct Script Usage

You can also run the script directly for more control:

```bash
# Monitor specific PIDs in real-time
sudo ./ips_monitor.sh --realtime 1234,5678

# Save output to file
sudo ./ips_monitor.sh --output my_log.txt 1234,5678

# Enable verbose output
sudo ./ips_monitor.sh --verbose --realtime 1234

# Keep the generated DTrace script
sudo ./ips_monitor.sh --keep-script --realtime 1234
```

### Script Options

- `--realtime`: Display output in real-time instead of saving to file
- `--output FILE`: Specify output file name (default: timestamped file)
- `--verbose`: Enable verbose output during setup
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
=== Monitoring root PIDs and their descendants ===
=== Root PIDs: 1234 5678 ===
Initialization complete. Starting monitoring...

➕ NEW_DESCENDANT: PID 9999 created by process 1234
SOCKET [PID 1234]: domain=2, type=1, protocol=6
  -> AF_INET (IPv4)
  -> SOCK_STREAM (TCP)
SOCKET_SUCCESS [PID 1234]: FD=5

CONNECT_ENTRY [PID 1234]: FD=5, addr_len=16
  -> 🎯 IPv4: 142.250.191.14:443
✅ CONNECT_SUCCESS [PID 1234]

WRITE [PID 1234]: FD=5, bytes=517
READ [PID 1234]: FD=5, bytes=1024

=== ⏰ MINUTE STATISTICS ===
Total IP connections: 3
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
make monitor-chrome
# or
make monitor-firefox
```

### Monitor Development Tools
```bash
make monitor-custom PROC=node
make monitor-custom PROC=python
```

### Debug Network Issues
```bash
# Monitor and save to log for analysis
make log-claude
# Then examine the log file in ./logs/
```

### Security Auditing
```bash
# Monitor a suspicious process
make monitor-pid PID=suspicious_pid
```

## Log Files

When not using `--realtime`, logs are saved with timestamps:
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
❌ No Claude processes found
```
**Solution**: Check if the process is running:
```bash
make show-processes
# or
ps aux | grep claude
```

### DTrace Issues
If DTrace fails to start, ensure:
- You're on macOS (DTrace support varies on other systems)
- System Integrity Protection (SIP) isn't blocking DTrace
- No other DTrace sessions are running

## File Structure

```
.
├── ips_monitor.sh          # Main monitoring script
├── Makefile               # Easy-to-use commands
├── README.md              # This file
└── logs/                  # Log files (created by make setup)
    ├── claude_*.log
    ├── chrome_*.log
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