# encoding: utf-8

namespace :metrics do
  begin
    require 'flay'

    project = Devtools.project

    compatible_scores = %w(mri-1.9.3 mri-2.0.0)

    unless compatible_scores.include?(Devtools.rvm)
      task :flay do
        $stderr.puts "Flay is disabled under #{Devtools.rvm} since it is not score compatible with other implementations"
      end
    else
       # original code by Marty Andrews:
      # http://blog.martyandrews.net/2009/05/enforcing-ruby-code-quality.html
      desc 'Analyze for code duplication'
      task :flay do
        config  = project.flay
        threshold   = config.threshold
        total_score = config.total_score
        files = Flay.expand_dirs_to_files(project.lib_dir).sort

        # run flay once without a threshold to ensure the max mass matches the threshold
        flay = Flay.new(:fuzzy => false, :verbose => false, :mass => 0)
        flay.process(*files)
        flay.analyze

        max = (flay.masses.map { |hash, mass| mass.to_f / flay.hashes[hash].size }.max) || 0
        unless max >= threshold
          raise "Adjust flay threshold down to #{max}"
        end

        total = flay.masses.reduce(0.0) { |total, (hash, mass)| total + (mass.to_f / flay.hashes[hash].size) }
        unless total == total_score
          raise "Flay total is now #{total}, but expected #{total_score}"
        end

        # run flay a second time with the threshold set
        flay = Flay.new(:fuzzy => false, :verbose => false, :mass => threshold.succ)
        flay.process(*files)
        flay.analyze

        if flay.masses.any?
          flay.report
          raise "#{flay.masses.size} chunks of code have a duplicate mass > #{threshold}"
        end
      end
    end
  rescue LoadError
    task :flay do
      $stderr.puts 'Flay is not available. In order to run flay, you must: gem install flay'
    end
  end
end
