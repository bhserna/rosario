require "digest"
require "erb"
require "fileutils"
require "json"
require_relative "mysteries"

ROOT = File.expand_path("..", __dir__)
TEMPLATES = File.join(ROOT, "templates")
STATIC = File.join(ROOT, "static")

Day = Data.define(:wday, :name)
Page = Data.define(:path, :template, :locals)

ServiceWorker = Data.define(:files, :version) do
  def self.from(rendered)
    static = Dir.children(STATIC).sort
    bodies = rendered.map(&:last) + static.map { |name| File.read(File.join(STATIC, name)) }

    new(
      rendered.map { |path, _body| "./#{path}" } + static.map { |name| "./#{name}" },
      Digest::SHA256.hexdigest(bodies.join)[0, 12]
    )
  end

  def path
    "sw.js"
  end

  def template
    "sw.js.erb"
  end

  def locals
    { files: files, version: version }
  end
end

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

def render_pages
  groups = GROUPS.map { |group| Group.from(group) }
  pages(groups).map { |page| [page.path, render(page.template, **page.locals)] }
end

def write_service_worker(root, rendered)
  worker = ServiceWorker.from(rendered)
  write_page(root, worker.path, render(worker.template, **worker.locals))
end

def build(root = File.join(ROOT, "build"))
  FileUtils.mkdir_p(root)
  copy_static(root)

  rendered = render_pages
  write_service_worker(root, rendered)
  rendered.each { |path, body| write_page(root, path, body) }
end

build if __FILE__ == $PROGRAM_NAME
