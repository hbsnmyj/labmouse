def grep_keys(text)
  Hash[*text.scan(/^(.*?)=(.*)$/).flatten]
end

def grep_block(text)
  block_regex = /START (.*?) (.*?$)\n(.*?)END \1/m
  text.scan(block_regex).map{|match_list|
    ParsedBlock.new({:name => match_list[0], :id => match_list[1], :content => match_list[2], :children => grep_block(match_list[2]),
    :keys => grep_keys(match_list[2].gsub(block_regex,''))})
  }
end

class ParsedBlock
  def initialize(arg)
    case arg
      when Hash then @parsed = arg
      else raise
    end
  end

  def key(key)
    @parsed[:keys][key]
  end

  def name
    @parsed[:name]
  end

  def id
    @parsed[:id]
  end

  def [](*args)
    case args.size
      when 0 then
        @parsed[:children]
      when 1 then
        @parsed[:children].select{|b| b.name == args[0]}
      when 2 then
        @parsed[:children].find{|b| b.name == args[0] && b.id == args[1]}
      else
        raise 'Too many arguments.'
    end
  end


  def to_s
    @parsed.to_s
  end
end