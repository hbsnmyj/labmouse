#!/bin/env ruby

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
        ["echo HELLO %{:a} %{:b} %{:a}", "cmd", "echo1", ""]
    ]
    exp = ExperimentRun.new({:a=>1, :b=>2},command_list)
    exp.run("test1")
  end

  def test_parse_block
    text = "START RUN run01\nSTART LABEL test\nPARAMS=test\nEND LABEL\nSTART LABEL asdlf\nSTART COMMAND TEST\nPARAMS=2\nEND COMMAND\nEND LABEL\nSTART COMMAND test\n\nEND COMMAND\nEND RUN 01\n"
    parsed = grep_block(text)[0]
    assert_equal('asdlf',parsed['LABEL','asdlf'].id)
    assert_equal('LABEL',parsed['LABEL','asdlf'].name)
  end

  def test_parse_block2
    text = 'START RUN test1
RUNSTART=2017-06-12 17:25:23 -0400
RUNPARAM={:a=>1, :b=>2}
START COMMAND echo1
CMD=echo HELLO 1 2 1
HELLO 1 2 1
TIME=0.0034558529987407383
END COMMAND echo1
RUNEND=2017-06-12 17:25:23 -0400
END RUN test1
START RUN test2
RUNSTART=2017-06-12 17:25:23 -0400
RUNPARAM={:a=>1, :b=>2}
START COMMAND echo1
CMD=echo HELLO 1 2 1
HELLO 1 2 1
TIME=0.0034558529987407383
END COMMAND echo1
RUNEND=2017-06-12 17:25:23 -0400
END RUN test2
'
    parsed = grep_block(text)[0]
    assert_equal('test1',parsed.id)
    assert_equal('2017-06-12 17:25:23 -0400',parsed.key('RUNSTART'))
    assert_equal('0.0034558529987407383',parsed['COMMAND','echo1'].key('TIME'))
  end

  def test_run_file
    command_list = [
        ["echo HELLO %{:a} %{:b} %{:a}", "cmd", "echo1", ""],
        ["echo HELLO2 %{:a} %{:b} %{:a}", "cmd", "echo2", ""]
    ]
    exp = ExperimentRun.new({:a=>1, :b=>2},command_list)
    runs = ExperimentRuns.new([exp, exp])
    runs.dump_file('test.config')
    runs.dump_run_script('test.rb', 'test.config')
    FileUtils::remove('test.config')
    FileUtils::remove('test.rb')
  end
end
