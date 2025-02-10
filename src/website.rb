# frozen_string_literal: true

class Website
  ROOT = Bundler.root
  YAML_FILE = ROOT.join("site.yml")
  WEB_ROOT = ROOT.join("www")

  STATIC_DIR = ROOT.join("static")
  PAGES_FILE = ROOT.join("src", "pages.rb")
  WATCHED_FILES = [YAML_FILE, PAGES_FILE, STATIC_DIR]

  def serve
    puts "🚀 Starting server..."
    server = WEBrick::HTTPServer.new(Port: 8000, DocumentRoot: WEB_ROOT)
    trap("INT") { server.shutdown }
    puts "🚀 Serving on http://localhost:8000"
    server.start
  end

  def reload
    load PAGES_FILE
    puts "✅ Reloaded #{PAGES_FILE}"
    @yaml = YAML.load_file(YAML_FILE, symbolize_names: true)
    puts "✅ Reloaded #{YAML_FILE}"
  end

  def generate
    reload
    verify_web_root
    copy_assets
    generate_pages
  end

  private

  def verify_web_root
    unless Dir.exist?(WEB_ROOT)
      Dir.mkdir(WEB_ROOT)
      puts "✅ Created directory #{WEB_ROOT}"
    end
  end

  def copy_assets
    FileUtils.cp_r(STATIC_DIR, WEB_ROOT)
    puts "✅ Copied #{STATIC_DIR} to #{WEB_ROOT}"
  end

  def generate_pages
    ApplicationPage.descendants.each do |page_class|
      page = page_class.new(@yaml)
      filepath = WEB_ROOT.join(page.filename)
      File.open(filepath, "w") { |file| file.write(page.call) }
      puts "✅ Generated #{filepath}"
    end
  end
end
