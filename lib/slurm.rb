require 'open3'

require 'pathname'

module Labmouse
class SLURM
  def self.generate_job(params, cmd, cooldown = 0)
    scripts = "#!/bin/bash\n\n"

    if params.has_key? :name
      scripts += "#SBATCH -J #{params[:name]}\n"
    else
      scripts += "#SBATCH -J slurm_job\n"
    end

    if params.has_key? :node
      scripts += "#SBATCH -N #{params[:node]}\n"
    else
      scripts += "#SBATCH -N 1\n"
    end

    if params.has_key? :partition
      scripts += "#SBATCH -p #{params[:partition]}\n"
    else
      scripts += "#SBATCH -p regular\n"
    end

    if params.has_key? :qos
      scripts += "#SBATCH --qos #{params[:qos]}\n"
    end

    if params.has_key? :license
      scripts += "#SBATCH -L #{params[:license]}"
    end

    if params.has_key? :exclude
      scripts += "#SBATCH -x #{params[:exclude]}\n"
    end

    if params.has_key? :constraint
      scripts += "#SBATCH -C #{params[:constraint]}\n"
    end

    if params.has_key? :output_dir
      scripts += "#SBATCH -o #{params[:output_dir]}/slurm-%j.out\n"
      scripts += "#SBATCH -e #{params[:output_dir]}/slurm-%j.out\n"
    end

    scripts += "\n#{cmd}\n"

    if cooldown != 0
        scripts += "#{Pathname(File.absolute_path(__FILE__)).dirname}/reschedule_all_job_after.sh #{cooldown}\n"
    end

    scripts
  end

  def self.dump_job(pathname, script)
    File.open(pathname,'w').each do |f|
      f.puts(script)
    end

    File.chmod(0700, pathname)
  end

  def self.submit_job(script, afterok = [], afterany = [], hold = false, singleton = false)
    cmd = sbatch_command(afterok, afterany, hold, singleton)

    output = ""
    Open3.pipeline_rw(cmd){|fin, lout, wt|
      fin.puts(script)
      fin.close
      output = lout.read
    }

    mobj = /Submitted batch job (\d+)$/.match(output)
    if mobj
      job_id = mobj[1]
      File.write("#{job_id}.sbatch",script)
      job_id
    else
        raise Exception.new("Failed to submit job:\nScript: #{script}\nError: #{output}")
    end
  end

  def self.release(job_id)
    system("scontrol release #{job_id}")
  end

  def self.sbatch_command(afterok, afterany, hold, singleton)
    cmd = 'sbatch'
    cmd += ' -H' if hold
    dependency_list = []
    dependency_list << 'afterok:' + afterok.join(':') if afterok.any?
    dependency_list << 'afterany:' + afterany.join(':') if afterany.any?
    dependency_list << 'singleton' if singleton
    cmd += " --dependency=#{dependency_list.join(',')}"
  end
end

class SLURMRunner
  def initialize(runs)
    @runs = runs
  end

  def create_job(prefix, indexes, ids, cooldown, singleton = false)
    run_file = prefix + '.config'
    job_script = File.absolute_path(prefix + '_job.rb')
    @runs.dump_file(prefix + '.config')
    @runs.dump_run_script(job_script, run_file)
    job_ids = []
    indexes.lazy.zip(ids).each{|index, id|
      script = SLURM.generate_job(@runs[index].params, "#{job_script} #{index} #{id}", cooldown)
      hold = !job_ids.any?
      if hold
          afterany = []
      else
          afterany = job_ids[-1..-1]
      end
      job_id = SLURM.submit_job(script, [], afterany, hold, singleton)
      job_ids.push(job_id)
      sleep 1
    }
    SLURM.release(job_ids[0])
  end
end

end
