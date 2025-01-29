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
        h1 { t("info", "name") }
        t("info", "links").each do |link|
          a(href: link["link"], target: "_blank") { link["name"] }
        end
        a(href: "/resume.html") { "Resume" }
        a(href: "mailto:#{t("info", "email")}") { "Email" }
      end
    end
  end
end

class ResumeGrid < Phlex::HTML
  def initialize(a, b, c, d)
    @a = a; @b = b; @c = c; @d = d
  end

  def view_template
    div do
      div(class: "resume-row") do
        h3 { @a }
        span { @b }
      end
      div(class: "resume-row") do
        span { @c }
        span { @d }
      end
    end
  end
end

class ResumeSection < Phlex::HTML
  def initialize(title)
    @title = title
  end

  def view_template
    section do
      header do
        h3 { @title }
        hr
      end
      yield
    end
  end
end

class ResumeWork < Phlex::HTML
  def initialize(job)
    @job= job
  end

  def view_template
    render ResumeGrid.new(
      @job["company"],
      @job["location"],
      @job["position"],
      @job["start_date"] + " - " + @job["end_date"],
    )
    ul { @job["details"].each { |point| li { point } } }
  end
end

class Resume < Phlex::HTML
  def view_template
    render Page.new(title: "Resume") do
      main(class: "resume") do
        section do
          render ResumeGrid.new(
            t("info", "name"),
            t("info", "website"),
            t("info", "role"),
            t("info", "email"),
          )
        end

        render ResumeSection.new("Experience") do
          t("resume", "experience").each do |job|
            render ResumeWork.new(job)
          end
        end

        render ResumeSection.new("Education") do
          t("resume", "education").each do |edu|
            render ResumeGrid.new(
              edu["institution"],
              edu["location"],
              edu["qualification"],
              edu["start_date"] + " - " + edu["end_date"],
            )
          end
        end

        render ResumeSection.new("Projects") do
          t("resume", "projects").each do |project|
            div do
              h3 do
                plain project["name"]
                plain " ("
                a(href: project["link"], target: "_blank") { project["link"].sub("https://", "") }
                plain ")"
              end
              p { project["summary"] }
            end
          end
        end

        render ResumeSection.new("Skills") do
          t("resume", "skills").each do |skill|
            div do
              h3 { skill["key"] }
              p { skill["values"].join(", ") }
            end
          end
        end
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
  generate("resume.html", Resume)
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
