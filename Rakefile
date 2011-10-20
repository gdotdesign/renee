ROOT = File.expand_path(File.dirname(__FILE__))

task :default => :test

def lsh(cmd, &block)
  out, code = lsh_with_code(cmd, &block)
  code == 0 ? out : raise(out.empty? ? "Running `#{cmd}' failed. Run this command directly for more detailed output." : out)
end

def lsh_with_code(cmd, &block)
  cmd << " 2>&1"
  outbuf = ''
  outbuf = `#{cmd}`
  if $? == 0
    block.call(outbuf) if block
  end
  [outbuf, $?]
end

renee_gems = %w[
  renee-core
  renee-render
  renee
].freeze

desc "build #{renee_gems.join(', ')} gems"
task :build do
  renee_gems.each do |g|
    Dir.chdir(g) do
      lsh "mkdir -p pkg && gem build #{g}.gemspec && mv *.gem pkg"
      puts "#{g} built"
    end
  end
end

task :release => [:build, :doc] do
  require File.join(ROOT, 'renee', 'lib', 'renee', 'version')
  version_tag = "v#{Renee::VERSION}"
  begin
    raise("#{version_tag} has already been committed") if lsh('git tag').split(/\n/).include?(version_tag)
    sh "git tag #{version_tag}"
    puts "adding tag #{version_tag}"
    renee_gems.each do |g|
      Dir.chdir(g) do
        sh "gem push pkg/#{g}-#{Renee::VERSION}.gem"
        puts "#{g} pushed"
      end
    end
    sh "git push"
    sh "git push --tags"
  rescue
    puts "something went wrong"
    sh "git tag -d #{version_tag}"
    raise
  end
end

task :install => :build do
  require File.join(ROOT, 'renee', 'lib', 'renee', 'version')
  renee_gems.each do |g|
    Dir.chdir(g) do
      lsh "gem install pkg/#{g}-#{Renee::VERSION}.gem"
      puts "#{g} installed"
    end
  end
end

renee_gems_tasks = Hash[renee_gems.map{|rg| [rg, :"test_#{rg.gsub('-', '_')}"]}].freeze

desc "Run tests for all padrino stack gems"
task :test => renee_gems_tasks.values

renee_gems_tasks.each do |g, tn|
  desc "Run tests for #{g}"
  task tn do
    sh "cd #{File.join(ROOT, g)} && #{Gem.ruby} -S rake test"
  end
end

desc "Generate documentation for the Padrino framework"
task :doc do
  renee_gems.each do |name|
    sh "cd #{File.join(ROOT, name.to_s)} && #{Gem.ruby} -S rake doc"
  end
end