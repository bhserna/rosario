require "erb"
require "fileutils"
require_relative "mysteries"

ROOT = File.expand_path("..", __dir__)
TEMPLATES = File.join(ROOT, "templates")
STATIC = File.join(ROOT, "static")

Day = Data.define(:wday, :name)
Mystery = Data.define(:title, :reading)

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

def build(root = File.join(ROOT, "build"))
  FileUtils.mkdir_p(root)
  copy_static(root)

  groups = GROUPS.map { |group| Group.from(group) }
  by_weekday = groups_by_weekday(groups)
  write_page(root, "index.html", render("index.html.erb", groups: groups))
  write_page(root, "today.html", render("today.html.erb", by_weekday: by_weekday))

  groups.each do |group|
    write_page(root, "#{group.id}.html", render("group.html.erb", group: group))
    group.mysteries.each_with_index do |mystery, index|
      number = index + 1
      write_page(
        root,
        "misterios/#{group.id}-#{number}.html",
        render("mystery.html.erb", group: group, mystery: mystery, number: number)
      )
    end
  end
end

build if __FILE__ == $PROGRAM_NAME
