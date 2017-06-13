Gem::Specification.new do |s|
    s.name = 'labmouse'
    s.authors = ["Haoyuan Xing"]
    s.version = '0.0.20170607'
    s.email = 'hbsnmyj@gmail.com'
    s.files = ["lib/labmouse.rb", "lib/parameters.rb", 'lib/experiment.rb',
               'lib/result_parser.rb', 'lib/slurm.rb', 'lib/reschedule_all_job_after.sh',
               'lib/resubmit_job.sh'
              ]
    s.summary = 'A very simple experimental framework'
end
