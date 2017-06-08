#!/bin/ruby

require "test/unit"
require "labmouse"

class TestLabmouse < Test::Unit::TestCase
    def test_simple
        list1 = [{"a"=>1},{"a"=>2}]
        list2 = [{"b"=>1},{"b"=>2}]
        result = [{"a"=>1, "b"=>1}, {"a"=>1, "b"=>2}, {"a"=>2, "b"=>1}, {"a"=>2, "b"=>2}]
        assert_equal(result, Labmouse::Parameters.new(list1).prod(list2).params)
        assert_equal(result, Labmouse::Parameters.new().pzip(["a"],[[1],[2]]).pzip(["b"], [[1],[2]]).params)
    end
end
