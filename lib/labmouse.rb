#!/bin/ruby
module Labmouse
    class Parameters
        include Enumerable
        attr_reader :params
        def initialize(params = [])
            @params = params
        end
        def prod(list_of_params)
            if @params.empty?
                Parameters.new list_of_params
            else
                Parameters.new @params.flat_map{|p|
                    list_of_params.map{ |np|
                        p.merge(np)
                    }
                }
            end
        end
        def pzip(names, list_of_lists)
            list_of_params = list_of_lists.map{|p|
                Hash[names.zip(p)]
            }
            return self.prod(list_of_params)
        end
        def count
            @params.count
        end
        def each(start_index=0, stop_index=-1)
            @params.each(start_index, stop_index)
        end
    end

    def fhash(string, hash)
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

    def run_cmd(hcmd, params)
        command_text = fhash(hcmd[:text], params)
        if hcmd[:options] =~ /time/
            command_text = "time -p #{command_text}"
        end
        puts "CMD=#{command_text}"
        system(ENV['SHELL'], "-c", command_text)
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
                send(func_name, hcmd, @params)
                if hcmd[:name] != ""
                    puts "END COMMAND"
                end
            }
            puts "RUNEND=" + Time.now.inspect
            puts "END RUN"
        end
    end
end
