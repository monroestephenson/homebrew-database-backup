class DatabaseBackup < Formula
  desc "Powerful database backup CLI tool with multiple database support"
  homepage "https://github.com/monroestephenson/database_backup"
  url "https://github.com/monroestephenson/database_backup/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "c7995f7ad7f5ed248e2cc907c1742a04b57cd43f08dceb2957fd3589e07bcb8b"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "spdlog"
  depends_on "nlohmann-json"
  depends_on "cli11"
  depends_on "mysql-connector-c++" => :optional
  depends_on "libpq" => :optional
  depends_on "mongo-cxx-driver" => :optional
  depends_on "sqlite3" => :optional

  def install
    # Remove build directory if it exists
    rm_rf "build"
    rm_rf "tests"  # Remove tests directory entirely
    rm_rf "external"  # Remove external directory if it exists
    mkdir "build"
    
    cd "build" do
      # Configure without tests and enable all database support
      system "cmake", "..", "-DBUILD_TESTS=OFF",
                           "-DUSE_POSTGRESQL=ON",
                           "-DUSE_MYSQL=ON",
                           "-DUSE_SQLITE=ON"
      system "make"
    end
    
    # Install the binary
    bin.install "build/database-backup" => "database-backup"
    
    # Create and install the wrapper script
    wrapper = <<~EOS
      #!/bin/bash
      
      # Default config location
      CONFIG_FILE="$HOME/.config/db-backup/config.json"
      
      # Function to show usage
      show_usage() {
          echo "Database Backup CLI Tool"
          echo
          echo "Usage: database-backup <command> [options]"
          echo
          echo "Commands:"
          echo "  backup [--type <full|incremental|differential>]  Perform a backup"
          echo "  restore <filename>                              Restore from backup"
          echo "  schedule                                       Start scheduled backups"
          echo "  verify <filename>                              Verify backup integrity"
          echo "  list                                          List available backups"
          echo
          echo "Options:"
          echo "  --config <path>    Use specific config file (default: ~/.config/db-backup/config.json)"
          echo "  --help            Show this help message"
          echo "  --version         Show version information"
      }
      
      # Parse command line arguments
      while [[ $# -gt 0 ]]; do
          case $1 in
              --help)
                  show_usage
                  exit 0
                  ;;
              --version)
                  echo "Database Backup CLI v1.0.0"
                  exit 0
                  ;;
              --config)
                  CONFIG_FILE="$2"
                  shift 2
                  ;;
              *)
                  break
                  ;;
          esac
      done
      
      # Execute the CLI tool with all arguments
      exec "#{bin}/database-backup" "$@" --config "$CONFIG_FILE"
    EOS
    
    (bin/"database-backup-cli").write(wrapper)
    chmod 0755, bin/"database-backup-cli"
    
    # Create and install config template
    config = <<~EOS
      {
          "database": {
              "type": "mysql",
              "host": "localhost",
              "port": 3306,
              "username": "${DB_USER}",
              "password": "${DB_PASSWORD}",
              "database": "mydb"
          },
          "storage": {
              "localPath": "./backups",
              "cloudProvider": "aws",
              "cloudPath": "my-backup-bucket/database-backups"
          },
          "logging": {
              "logPath": "./logs",
              "logLevel": "info",
              "enableNotifications": true,
              "notificationEndpoint": "https://hooks.slack.com/services/${SLACK_WEBHOOK_ID}"
          },
          "backup": {
              "compression": {
                  "enabled": true,
                  "format": "gzip",
                  "level": "medium"
              },
              "retention": {
                  "days": 30,
                  "maxBackups": 10
              },
              "schedule": {
                  "enabled": true,
                  "cron": "0 0 * * *"
              }
          },
          "security": {
              "encryption": {
                  "enabled": true,
                  "algorithm": "AES-256-GCM",
                  "keyPath": "${ENCRYPTION_KEY_PATH}"
              }
          }
      }
    EOS
    
    (etc/"database_backup").mkpath
    config_template = etc/"database_backup/config.template.json"
    config_template.write(config) unless config_template.exist?
    
    # Install documentation
    doc.install "README.md" if File.exist?("README.md")
  end

  def post_install
    # Create necessary directories
    (var/"log/database_backup").mkpath
    (var/"database_backup/backups").mkpath
    (etc/"database_backup").mkpath
    
    # Print instructions for user directory setup
    ohai "Next Steps"
    puts <<~EOS
      To complete the setup:
      
      1. Create the config directory:
         mkdir -p ~/.config/db-backup
      
      2. Copy the config template:
         cp #{etc}/database_backup/config.template.json ~/.config/db-backup/config.json
      
      3. Set up your environment variables in ~/.zshrc or ~/.bash_profile:
         export DB_USER=your_database_user
         export DB_PASSWORD=your_database_password
         export SLACK_WEBHOOK_ID=your_webhook_id  # Optional
         export ENCRYPTION_KEY_PATH=/path/to/your/key  # Optional
      
      4. Edit your config file:
         nano ~/.config/db-backup/config.json
    EOS
  end

  def caveats
    <<~EOS
      Database Backup CLI has been installed!
      
      To get started:
      
      1. Set up your environment variables in ~/.zshrc or ~/.bash_profile:
         export DB_USER=your_database_user
         export DB_PASSWORD=your_database_password
         export SLACK_WEBHOOK_ID=your_webhook_id  # Optional
         export ENCRYPTION_KEY_PATH=/path/to/your/key  # Optional
      
      2. Your configuration file is at:
         ~/.config/db-backup/config.json
      
      3. Basic usage:
         database-backup backup --type full     # Perform a full backup
         database-backup restore <backup-file>  # Restore from backup
         database-backup --help                # Show all commands
      
      For more information, see:
        #{doc}/README.md
    EOS
  end

  test do
    system "#{bin}/database-backup", "--help"
  end
end 