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