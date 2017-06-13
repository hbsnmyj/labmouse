#!/bin/env ruby
#
require "labmouse"

include Labmouse

params = Parameters.new()
    .pzip(["a"], [[1],[2]])
    .pzip(["b"], [[1],[2]])
    .pzip([:nodes], [[1],[2]])
    .pzip([:partition], [["storage"]])
    .params

command_list = [
    ["echo HELLO %{:a} %{:b} %{:a}", "cmd", "echo1", ""],
    ["echo HELLO %{:b} %{:a} %{:b}", "cmd", "echo2", ""]
]

runs = params.map do |p|
    ExperimentRun.new(p, command_list)
end

runs = ExperimentRuns.new(runs)

indexes = [0,1,2,3]
ids = ['test1','test2','test3','test4']

runner = SLURMRunner.new(runs)
runner.create_job("test", indexes, ids, 600)
