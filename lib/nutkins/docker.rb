require 'open3'

module Nutkins::Docker
  def self.image_id_for_tag tag
    self.run_get_stdout 'inspect', '--format="{{.Id}}"', tag
  end

  def self.kill_and_remove_container id
    raise "issue killing existing container" unless Nutkins::Docker.run 'kill', id
    raise "issue removing existing container" unless Nutkins::Docker.run 'rm', id
  end

  def self.container_id_for_tag tag, running: false
    flags = running ? '' : ' -a'
    regex = /^[0-9a-f]+ +#{Regexp.escape tag} +/
    `docker ps#{flags}`.each_line do |line|
      return line.split(' ')[0] if line =~ regex
    end
    nil
  end

  def self.get_short_commit commit
    if /^sha256:/.match(commit)
      commit[7...19]
    else
      commit
    end
  end

  def self.container_id_for_name name
    self.run_get_stdout 'inspect', '--format="{{.Id}}"', name
  end

  def self.run_get_stdout *args
    stdout_str, stderr_str, status = Open3.capture3 'docker', *args
    status.success? ? stdout_str.chomp : nil
  end

  def self.run *args, stdout: false, stderr: true
    stdout_backup = ! stdout && $stdout.clone
    stderr_backup = ! stderr && $stderr.clone
    $stdout.reopen File.new('/dev/null', 'w') unless stdout
    $stderr.reopen File.new('/dev/null', 'w') unless stderr
    begin
      system 'docker', *args
    ensure
      $stdout.reopen stdout_backup unless stdout
      $stderr.reopen stderr_backup unless stderr
    end
  end
end
