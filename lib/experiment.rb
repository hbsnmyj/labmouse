require 'benchmark'
require 'yaml'
require 'open3'

module Labmouse

def self.fhash(string, hash)
  obj = string.match(/%\{(.*?)\}/)
  while obj
    start = obj.begin(0)
    endpos = obj.end(0)
    key = obj[1]
    string.slice!(start, endpos - start)
    string.insert(start, "#{hash[eval(key)]}")
    obj = string.match(/%\{(.*?)\}/)
  end
  return string
end

def self.run_cmd(hcmd, params)
  command_text = fhash(hcmd[:text], params)
  puts "CMD=#{command_text}"
  time = Benchmark.measure {
      Open3.popen2e(command_text) do |stdin, stdoe, wait_thr|
          while line = stdoe.gets
              puts line
          end
          exit_status = wait_thr.value
          puts "EXIT_STATUS=#{exit_status}"
      end
  }
  puts "TIME=#{time.real}"
end

class ExperimentRun
  attr_reader :params,:commands
  def initialize(params, commands)
    @params = params
    @commands = commands
  end

  def run(run_id)
    puts "START RUN #{run_id}"
    puts "RUNSTART=" + Time.now.inspect
    puts "RUNPARAM=#{@params}"
    @commands.each{|cmd|
      hcmd = Hash[[:text, :type, :name, :options].zip(cmd)]
      if hcmd[:name] != ""
        puts "START COMMAND #{hcmd[:name]}"
      end
      func_name = "run_#{hcmd[:type]}"
      Labmouse.send(func_name, hcmd, @params)
      if hcmd[:name] != ""
        puts "END COMMAND #{hcmd[:name]}"
      end
    }
    puts "RUNEND=" + Time.now.inspect
    puts "END RUN #{run_id}"
  end

end

class ExperimentRuns
  def initialize(runs)
    @runs = runs
  end

  def dump_file(filename)
    File.open(filename, "w") do |file|
      @runs.each { |run|
        file.puts(run.to_yaml)
        file.puts()
      }
    end
  end

  def self.from_file(filename)
    temp = $/
    $/="\n\n"
    runs = []
    File.open(filename, 'r').each do |line|
      runs << YAML::load(line)
    end
    $/ = temp
    ExperimentRuns.new(runs)
  end

  def run(index, id)
    @runs[index].run(id)
  end

  def dump_run_script(path, runfile)
    script = "#!/bin/env ruby
      require 'labmouse'
      runs = Labmouse::ExperimentRuns.from_file('#{runfile}')
      runs.run(Integer(ARGV[0]),ARGV[1])
    "
    File.open(path, 'w') do |file|
      file.puts(script)
    end
    File.chmod(0700, path)
  end

  def [](index)
    return @runs[index]
  end

  def length()
    return @runs.length
  end
end

class LocalRunner
  def initialize(runs, cooldown = 0)
    @runs = runs
    @cooldown = cooldown
  end

  def create_job(prefix, indexes, ids)
    path = "#{prefix}_run.sh"
    @runs.dump_file(prefix + '.config')
    job_script = prefix + '_job.rb'
    job_script = File.absolute_path(job_script)
    @runs.dump_run_script(job_script, prefix + '.config')
    File.open(path, 'w') do |file|
      scripts = "#!/bin/bash\n\n"
      has_prev = false
      indexes.lazy.zip(ids).each{|index,id|
        if @cooldown != 0 and has_prev
          scripts += "sleep #{@cooldown}\n"
        end
        scripts += "#{job_script} #{index} #{id}\n\n"
        has_prev = true
      }
      file.write(scripts)
    end
    File.chmod(0700, path)
  end
end

end
