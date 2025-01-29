#!/usr/bin/env ruby

# frozen_string_literal: true

$stdout.sync = true

require "yaml"
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "phlex", "~> 1.11"
  gem "logger"
  gem "filewatcher"
  gem "webrick"
end

ROOT = File.expand_path("./www")
SITE = YAML.load_file("site.yml").freeze

def t(...)
  SITE.dig(...)
end

class Page < Phlex::HTML
  def initialize(title:)
    @title = title
  end

  def view_template
    doctype

    html do
      head do
        meta charset: "utf-8"
        meta name: "viewport", content: "width=device-width, initial-scale=1"
        link rel: "stylesheet", href: "/style.css"
        title { "#{@title} | #{t("info", "name")}" }
      end

      body do
        yield
      end
    end
  end
end

class Home < Phlex::HTML
  def view_template
    render Page.new(title: "Home") do
      main(class: "home") do
        h1(class: "home-name") { t("info", "name") }
        t("info", "links").each do |link|
          a(href: link["link"], target: "_blank") { link["name"] }
        end
        a(href: "mailto:#{t("info", "email")}") { "Email" }
      end
    end
  end
end

def serve
  puts "🚀 Starting server..."
  server = WEBrick::HTTPServer.new(Port: 8000, DocumentRoot: ROOT)
  trap("INT") { server.shutdown }
  puts "🚀 Serving on http://localhost:8000"
  server.start
end

def generate(filename, klass)
  file = File.new("#{ROOT}/#{filename}", "w")
  file.write(klass.call)
  file.close
  puts "✅ Generated #{file.path}"
end

def generate_all
  unless Dir.exist?(ROOT)
    Dir.mkdir(ROOT)
    puts "✅ Created directory #{ROOT}"
  end

  generate("index.html", Home)
end

case ARGV.first&.strip
when "serve"
  serve
when "watch"
  generate_all
  process = fork { serve }
  Process.detach(process)
  Filewatcher.new(["./site.yml"]).watch do |filename, event|
    puts "🔄 Reloading #{filename}"
    SITE = YAML.load_file("site.yml").freeze
    generate_all
  end
else
  generate_all
end
