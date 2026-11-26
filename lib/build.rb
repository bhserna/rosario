require "erb"
require "fileutils"
require_relative "mysteries"

ROOT = File.expand_path("..", __dir__)
TEMPLATES = File.join(ROOT, "templates")
STATIC = File.join(ROOT, "static")

Day = Data.define(:wday, :name)
Page = Data.define(:path, :template, :locals)

Mystery = Data.define(:title, :reading) do
  def page_path(group, number)
    "misterios/#{group.id}-#{number}.html"
  end

  def template
    "mystery.html.erb"
  end

  def page(group, number)
    Page.new(page_path(group, number), template, { group: group, mystery: self, number: number })
  end
end

Group = Data.define(:id, :name, :source, :days, :mysteries) do
  def self.from(hash)
    new(
      id: hash[:id],
      name: hash[:name],
      source: hash[:source],
      days: hash[:days].map { |day| Day.new(**day) },
      mysteries: hash[:mysteries].map { |mystery| Mystery.new(**mystery) }
    )
  end

  def day_label
    names = days.map(&:name)
    names[0] = names[0].capitalize
    names.join(" y ")
  end

  def page_path
    "#{id}.html"
  end

  def template
    "group.html.erb"
  end

  def page
    Page.new(page_path, template, { group: self })
  end

  def pages
    [page, *mysteries.each_with_index.map { |mystery, index| mystery.page(self, index + 1) }]
  end
end

def groups_by_weekday(groups)
  groups.each_with_object(Array.new(7)) do |group, ids|
    group.days.each { |day| ids[day.wday] = group.id }
  end
end

def render(template, **locals)
  erb = ERB.new(File.read(File.join(TEMPLATES, template)), trim_mode: "-")
  erb.result_with_hash(locals)
end

def write_page(root, path, content)
  destination = File.join(root, path)
  FileUtils.mkdir_p(File.dirname(destination))
  File.write(destination, content)
end

def copy_static(root)
  Dir.children(STATIC).each do |name|
    FileUtils.cp(File.join(STATIC, name), File.join(root, name))
  end
end

def pages(groups)
  [
    Page.new("index.html", "index.html.erb", { groups: groups }),
    Page.new("today.html", "today.html.erb", { by_weekday: groups_by_weekday(groups) }),
    *groups.flat_map(&:pages)
  ]
end

def build(root = File.join(ROOT, "build"))
  FileUtils.mkdir_p(root)
  copy_static(root)

  groups = GROUPS.map { |group| Group.from(group) }
  pages(groups).each do |page|
    write_page(root, page.path, render(page.template, **page.locals))
  end
end

build if __FILE__ == $PROGRAM_NAME
