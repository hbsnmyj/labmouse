#!/bin/ruby

require "test/unit"
require "labmouse"

include Labmouse

class TestLabmouse < Test::Unit::TestCase
  def test_simple
    list1 = [{"a"=>1},{"a"=>2}]
    list2 = [{"b"=>1},{"b"=>2}]
    result = [{"a"=>1, "b"=>1}, {"a"=>1, "b"=>2}, {"a"=>2, "b"=>1}, {"a"=>2, "b"=>2}]
    assert_equal(result, Parameters.new(list1).prod(list2).params)
    assert_equal(result, Parameters.new().pzip(["a"],[[1],[2]]).pzip(["b"], [[1],[2]]).params)
  end

  def test_run
    command_list = [
        ["echo HELLO %{:a} %{:b} %{:a}", "cmd", "echo1", "time"]
    ]
    exp = ExperimentRun.new({:a=>1, :b=>2},command_list)
    exp.run("test1")
  end
end
