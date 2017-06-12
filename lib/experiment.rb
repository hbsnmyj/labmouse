require 'benchmark'
require 'yaml'

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
    system(ENV['SHELL'], "-c", command_text)
  }
  puts "TIME=#{time.real}"
end

class ExperimentRun
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
    script = "#!/bin/ruby
      require 'labmouse'
      runs = Labmouse::ExperimentRuns.from_file('#{runfile}')
      runs.run(Integer(ARGV[0]),ARGV[1])
    "
    File.open(path, 'w') do |file|
      file.puts(script)
    end
    FileUtils.chmod(0700, path)
  end
end

class LocalRunner
  def initialize(runs, cooldown = 0)
    @runs = runs
  end

  def create_job(prefix, indexes, ids)
    runs.dump_file(prefix + '.config')
    job_script = prefix + '_job.rb'
    runs.dump_run_script(job_script)
    File.open(path, 'w') do |file|
      script = '#!/bin/bash\n\n'
      job_script = File.absolute_path(job_script)
      has_prev = false
      indexes.lazy.zip(ids).each{|index,id|
        if cooldown != 0 and has_prev
          scripts += "sleep #{cooldown}\n"
        end
        scripts += "#{job_script} #{index} #{id}\n\n"
        has_prev = true
      }
    end
  end
end

end
