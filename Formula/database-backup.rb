class DatabaseBackup < Formula
  desc "Powerful database backup CLI tool with multiple database support"
  homepage "https://github.com/monroestephenson/database_backup"
  url "https://github.com/monroestephenson/database_backup/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "b0ba22e038b515dc05f38455b61fcadc9b6d194768a470f8f23657c1756c2a45"
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
    mkdir "build"
    
    cd "build" do
      system "cmake", ".."
      system "make"
    end
    
    # Install the binary
    bin.install "build/my_db_backup_cli" => "db-backup"
    
    # Install shell wrapper script
    bin.install "src/db-backup" => "db-backup-wrapper"
    
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
         db-backup backup --type full     # Perform a full backup
         db-backup restore <backup-file>  # Restore from backup
         db-backup --help                # Show all commands
      
      For more information, see:
        #{doc}/README.md
    EOS
  end

  test do
    system "#{bin}/db-backup", "--version"
  end
end 