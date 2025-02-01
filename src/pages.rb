# frozen_string_literal: true

module Components
  class PageLayout < Phlex::HTML
    def initialize(title)
      @title = title
    end

    def view_template
      doctype

      html do
        head do
          meta charset: "utf-8"
          meta name: "viewport", content: "width=device-width, initial-scale=1"
          link rel: "stylesheet", href: "/style.css"
          title { @title }
        end

        body do
          yield
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
      @job = job
    end

    def view_template
      render ResumeGrid.new(
        @job[:company],
        @job[:location],
        @job[:position],
        @job[:start_date] + " - " + @job[:end_date],
      )
      ul { @job[:details].each { |point| li { point } } }
    end
  end
end

class ApplicationPage < Phlex::HTML
  include Components

  def self.descendants
    ObjectSpace.each_object(Class).select { |c| c < self }
  end

  def filename
    raise NotImplementedError
  end
end

class HomePage < ApplicationPage
  def initialize(data)
    @data = data
  end

  def filename
    "index.html"
  end

  def view_template
    render PageLayout.new("Home | #{@data[:info][:name]}") do
      main(class: "home") do
        h1 { @data[:info][:name] }
        @data[:info][:links].each do |link|
          a(href: link[:link], target: "_blank") { link[:name] }
        end
        a(href: "/resume.html") { "Resume" }
        a(href: "mailto:#{@data[:info][:email]}") { "Email" }
      end
    end
  end
end

class ResumePage < ApplicationPage
  def initialize(data)
    @data = data
  end

  def filename
    "resume.html"
  end

  def view_template
    render PageLayout.new("Resume | #{@data[:info][:name]}") do
      main(class: "resume") do
        section do
          render ResumeGrid.new(
            @data[:info][:name],
            @data[:info][:website],
            @data[:info][:role],
            @data[:info][:email],
          )
        end

        render ResumeSection.new("Experience") do
          @data[:resume][:experience].each do |job|
            render ResumeWork.new(job)
          end
        end

        render ResumeSection.new("Education") do
          @data[:resume][:education].each do |edu|
            render ResumeGrid.new(
              edu[:institution],
              edu[:location],
              edu[:qualification],
              edu[:start_date] + " - " + edu[:end_date],
            )
          end
        end

        render ResumeSection.new("Projects") do
          @data[:resume][:projects].each do |project|
            div do
              h3 do
                plain project[:name]
                plain " ("
                a(href: project[:link], target: "_blank") { project[:link].sub("https://", "") }
                plain ")"
              end
              p { project[:summary] }
            end
          end
        end

        render ResumeSection.new("Skills") do
          @data[:resume][:skills].each do |skill|
            div do
              h3 { skill[:key] }
              p { skill[:values].join(", ") }
            end
          end
        end
      end
    end
  end
end
