# IP Monitor Makefile
SCRIPT := ./ip_monitor.sh
LOG_DIR := ./logs
LOGFILE := $(shell date +%Y%m%d_%H%M%S).log

# Default target
.PHONY: help
help:
	@echo "IP Monitor - Network Connection Tracker"
	@echo ""
	@echo "Available targets:"
	@echo "  chrome    Monitor Chrome processes" 
	@echo "  firefox   Monitor Firefox processes"
	@echo "  yandex    Monitor Yandex processes"
	@echo "  pid       Monitor specific PID (usage: make pid PID=1234)"
	@echo "  app       Monitor custom app (usage: make app PROC=processname)"
	@echo "  setup             Create logs directory and make script executable"
	@echo "  clean             Remove old log files"
	@echo "  show    Show running processes that can be monitored"
	@echo "  help              Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make pid PID=1234"
	@echo "  make app PROC=node"
	@echo "  make yandex"
	@echo "  make chrome"
	@echo "  make firefox"

# Setup target
.PHONY: setup
setup:
	@echo "Setting up IP Monitor..."
	@mkdir -p $(LOG_DIR)
	@chmod +x $(SCRIPT)
	@echo "✅ Setup complete. Logs will be saved to $(LOG_DIR)/"

# Monitor Chrome processes
.PHONY: chrome
chrome: setup
	@echo "🔍 Looking for Chrome processes..."
	$(MAKE) app PROC=chrome

# Monitor Firefox processes
.PHONY: firefox
firefox: setup
	@echo "🔍 Looking for Firefox processes..."
	$(MAKE) app PROC=firefox

# Monitor Yandex processes
.PHONY: yandex
yandex: setup
	@echo "🔍 Looking for Yandex processes..."
	$(MAKE) app PROC=yandex

# Monitor specific PID
.PHONY: pid
pid: setup
	@if [ -z "$(PID)" ]; then \
		echo "❌ PID not specified. Usage: make pid PID=1234"; \
		exit 1; \
	fi
	@echo "📡 Monitoring PID: $(PID)"
	@sudo $(SCRIPT) --output "$(LOG_DIR)/$(LOGFILE)" $(PID)

# Monitor custom process by name
.PHONY: app
app: setup
	@if [ -z "$(PROC)" ]; then \
		echo "❌ Process name not specified. Usage: make app PROC=processname"; \
		exit 1; \
	fi
	@echo "🔍 Looking for $(PROC) processes..."
	@PIDS=$$(pgrep -i $(PROC) 2>/dev/null | tr '\n' ',' | sed 's/,$$//'); \
	if [ -z "$$PIDS" ]; then \
		echo "❌ No $(PROC) processes found"; \
		echo "💡 Try: make show PROC=$(PROC)"; \
		exit 1; \
	else \
		echo "📡 Monitoring $(PROC) PIDs: $$PIDS"; \
		sudo $(SCRIPT) --output "$(LOG_DIR)/$(LOGFILE)" $$PIDS; \
	fi

# Show running processes that can be monitored
.PHONY: show
show:
	@if [ -z "$(PROC)" ]; then \
		echo "❌ Process name not specified. Usage: make show PROC=processname"; \
		exit 1; \
	fi
	@echo "🔍 Looking for $(PROC) processes..."

	@echo "Claude processes:"
	@pgrep -l -i $(PROC) 2>/dev/null || echo "  (none found)"

# Clean old log files
.PHONY: clean
clean:
	@echo "🧹 Cleaning old log files..."
	@if [ -d "$(LOG_DIR)" ]; then \
		find $(LOG_DIR) -name "*.log" -mtime +7 -delete 2>/dev/null || true; \
		echo "✅ Removed log files older than 7 days"; \
	fi
	@echo "✅ Cleanup complete"
