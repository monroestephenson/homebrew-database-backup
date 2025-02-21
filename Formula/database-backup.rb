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
      # Configure without tests
      system "cmake", "..", "-DBUILD_TESTS=OFF"
      system "make"
    end
    
    # Install the binary
    bin.install "build/my_db_backup_cli" => "db-backup"
    
    # Create and install the wrapper script
    wrapper = <<~EOS
      #!/bin/bash
      
      # Default config location
      CONFIG_FILE="$HOME/.config/db-backup/config.json"
      
      # Function to show usage
      show_usage() {
          echo "Database Backup CLI Tool"
          echo
          echo "Usage: db-backup <command> [options]"
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
      exec "#{bin}/db-backup" "$@" --config "$CONFIG_FILE"
    EOS
    
    (bin/"db-backup-cli").write(wrapper)
    chmod 0755, bin/"db-backup-cli"
    
    # Install config template
    etc.install "config.json" => "database_backup/config.template.json"
    
    # Install documentation
    doc.install "README.md", "LICENSE"
  end

  def post_install
    # Create necessary directories
    (var/"log/database_backup").mkpath
    (var/"database_backup/backups").mkpath
    (etc/"database_backup").mkpath
    
    # Create user config directory
    system "mkdir", "-p", "#{ENV["HOME"]}/.config/db-backup"
    
    # Copy config template if it doesn't exist
    config_template = etc/"database_backup/config.template.json"
    user_config = "#{ENV["HOME"]}/.config/db-backup/config.json"
    system "cp", "-n", config_template, user_config unless File.exist?(user_config)
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
         db-backup-cli backup --type full     # Perform a full backup
         db-backup-cli restore <backup-file>  # Restore from backup
         db-backup-cli --help                # Show all commands
      
      For more information, see:
        #{doc}/README.md
    EOS
  end

  test do
    system "#{bin}/db-backup-cli", "--version"
  end
end 