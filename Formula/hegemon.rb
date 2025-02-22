class Hegemon < Formula
  desc "Powerful database backup and management CLI tool"
  homepage "https://github.com/monroestephenson/hegemon"
  url "https://github.com/monroestephenson/hegemon/archive/refs/tags/v1.0.13.tar.gz"
  sha256 "0c0424c75122dca46adef336871b0f41675b389f3554710a63d3ca86520be7de"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "spdlog"
  depends_on "nlohmann-json"
  depends_on "cli11"
  depends_on "openssl"
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
                           "-DUSE_SQLITE=ON",
                           "-DCMAKE_BUILD_TYPE=Release"
      system "make"
    end
    
    # Install the binary
    bin.install "build/hegemon" => "hegemon"
    
    # Create and install the wrapper script
    wrapper = <<~EOS
      #!/bin/bash
      
      # Default config location
      CONFIG_FILE="$HOME/.config/hegemon/config.json"
      
      # Function to show usage
      show_usage() {
          echo "Hegemon - Database Management CLI"
          echo
          echo "Usage: hegemon <command> [options]"
          echo
          echo "Commands:"
          echo "  backup [--type <full|incremental|differential>]  Perform a backup"
          echo "  restore <filename>                              Restore from backup"
          echo "  schedule                                       Start scheduled backups"
          echo "  verify <filename>                              Verify backup integrity"
          echo "  list                                          List available backups"
          echo
          echo "Options:"
          echo "  --config <path>    Use specific config file (default: ~/.config/hegemon/config.json)"
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
                  echo "Hegemon v1.0.13"
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
      exec "#{bin}/hegemon" "$@" --config "$CONFIG_FILE"
    EOS
    
    (bin/"hegemon-cli").write(wrapper)
    chmod 0755, bin/"hegemon-cli"
    
    # Create and install config template
    config = <<~EOS
      {
          "database": {
              "type": "mysql",
              "host": "localhost",
              "port": 3306,
              "credentials": {
                  "username": "${DB_USER}",
                  "passwordKey": "hegemon.mysql.${DB_USER}.password",
                  "preferredSources": ["keystore", "environment", "file"]
              },
              "database": "mydb"
          },
          "storage": {
              "localPath": "./backups",
              "cloudProvider": "local"
          },
          "logging": {
              "logPath": "./logs",
              "logLevel": "info",
              "enableNotifications": false
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
                  "enabled": false
              }
          },
          "security": {
              "encryption": {
                  "enabled": false
              },
              "credentialStore": {
                  "enabled": true,
                  "type": "keystore",
                  "keyPrefix": "hegemon",
                  "options": {
                      "service": "hegemon-db-backup"
                  }
              }
          }
      }
    EOS
    
    (etc/"hegemon").mkpath
    config_template = etc/"hegemon/config.template.json"
    config_template.write(config) unless config_template.exist?
    
    # Install documentation
    doc.install "README.md" if File.exist?("README.md")
  end

  def post_install
    # Create necessary directories
    (var/"log/hegemon").mkpath
    (var/"hegemon/backups").mkpath
    (etc/"hegemon").mkpath
    
    # Print instructions for user directory setup
    ohai "Next Steps"
    puts <<~EOS
      To complete the setup:
      
      1. Create the config directory:
         mkdir -p ~/.config/hegemon
      
      2. Copy the config template:
         cp #{etc}/hegemon/config.template.json ~/.config/hegemon/config.json
      
      3. Set up your environment variables in ~/.zshrc or ~/.bash_profile:
         export DB_USER=your_database_user
         export DB_PASSWORD=your_database_password
      
      4. Edit your config file:
         nano ~/.config/hegemon/config.json
      
      5. For secure credential storage:
         - On macOS, store your password in Keychain:
           security add-generic-password -s hegemon -a hegemon.mysql.$DB_USER.password -w
      
      6. Basic usage:
         hegemon backup --type full     # Perform a full backup
         hegemon restore <backup-file>  # Restore from backup
         hegemon list                  # List all backups
         hegemon verify <backup-file>  # Verify backup integrity
         hegemon --help               # Show all commands
      
      For more information, see:
        #{doc}/README.md
    EOS
  end

  def caveats
    <<~EOS
      Hegemon has been installed!
      
      To get started:
      
      1. Set up your environment variables in ~/.zshrc or ~/.bash_profile:
         export DB_USER=your_database_user
         export DB_PASSWORD=your_database_password
      
      2. Your configuration file is at:
         ~/.config/hegemon/config.json
      
      3. For secure credential storage:
         - On macOS, store your password in Keychain:
           security add-generic-password -s hegemon -a hegemon.mysql.$DB_USER.password -w
      
      4. Basic usage:
         hegemon backup --type full     # Perform a full backup
         hegemon restore <backup-file>  # Restore from backup
         hegemon list                  # List all backups
         hegemon verify <backup-file>  # Verify backup integrity
         hegemon --help               # Show all commands
      
      For more information, see:
        #{doc}/README.md
    EOS
  end

  test do
    system "#{bin}/hegemon", "--help"
  end
end 