require 'escape'
require 'securerandom'

module Minicron
  class Cron
    PATH = '/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'.freeze
    # Build the minicron command to be used in the crontab
    #
    # @param schedule [String]
    # @param command [String]
    # @return [String]
    def build_minicron_command(schedule, command)
      # Escape the command so it will work in bourne shells
      "#{schedule} #{Escape.shell_command(['minicron', 'run', command])}"
    end

    # Build the crontab multiline string that includes all the given jobs
    #
    # @param host [Minicron::Hub::Model::Host] a host instance with it's jobs and job schedules
    # @return [String]
    def build_crontab(host)
      # You have been warned..
      crontab = "#\n"
      crontab += "# This file was automatically generated by minicron at #{Time.now.utc}, DO NOT EDIT manually!\n"
      crontab += "#\n\n"

      # Set the path to something sensible by default, eventually this should be configurable
      crontab += "# ENV variables\n"
      crontab += "PATH=#{PATH}\n"
      crontab += "MAILTO=\"\"\n"
      crontab += "\n"

      # Add an entry to the crontab for each job schedule
      unless host.nil?
        host.jobs.each do |job|
          crontab += "# ID:   #{job.id}\n"
          crontab += "# Name: #{job.name}\n"
          crontab += "# Status: #{job.status}\n"

          if !job.schedules.empty?
            job.schedules.each do |schedule|
              crontab += "\t"
              crontab += '# ' unless job.enabled # comment out schedule if job isn't enabled
              crontab += "#{build_minicron_command(schedule.formatted, job.command)}\n"
            end
          else
            crontab += "\t# No schedules exist for this job\n"
          end

          crontab += "\n"
        end
      end

      crontab
    end
  end
end