class DatabaseBackup < Formula
  desc "Powerful database backup CLI tool with multiple database support"
  homepage "https://github.com/monroestephenson/database_backup"
  url "https://github.com/monroestephenson/database_backup/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "UPDATE_WITH_ACTUAL_SHA256_AFTER_RELEASE"
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
    system "mkdir", "build"
    system "cd", "build", "&&", "cmake", "..", "&&", "make"
    
    bin.install "build/my_db_backup_cli" => "db-backup"
    
    # Install config template
    etc.install "config.json" => "database_backup/config.template.json"
    
    # Install documentation
    doc.install "README.md", "LICENSE"
  end

  def post_install
    (var/"log/database_backup").mkpath
    (var/"database_backup/backups").mkpath
  end

  def caveats
    <<~EOS
      Configuration template has been installed to:
        #{etc}/database_backup/config.template.json
      
      Copy it to ~/.config/db-backup/config.json and modify as needed:
        mkdir -p ~/.config/db-backup
        cp #{etc}/database_backup/config.template.json ~/.config/db-backup/config.json
      
      Set up your environment variables in ~/.zshrc or ~/.bash_profile:
        export DB_USER=your_database_user
        export DB_PASSWORD=your_database_password
        export SLACK_WEBHOOK_ID=your_webhook_id
        export ENCRYPTION_KEY_PATH=/path/to/your/key
    EOS
  end

  test do
    system "#{bin}/db-backup", "--version"
  end
end 