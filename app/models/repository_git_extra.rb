require 'digest/sha1'

class RepositoryGitExtra < ActiveRecord::Base
  unloadable

  belongs_to :repository, :class_name => 'Repository', :foreign_key => 'repository_id'

  validates_associated :repository

  attr_accessible :id, :repository_id, :key, :git_http, :git_daemon, :git_notify, :default_branch

  after_initialize :set_values


  def validate_encoded_time(clear_time, encoded_time)
    valid = false
    begin
      cur_time_seconds = Time.new.utc.to_i
      test_time_seconds = clear_time.to_i
      if cur_time_seconds - test_time_seconds < 5*60
        key = read_attribute(:key)
        test_encoded = Digest::SHA1.hexdigest(clear_time.to_s + key.to_s)
        if test_encoded.to_s == encoded_time.to_s
          valid = true
        end
      end
    rescue Exception => e
      RedmineGitolite::GitHosting.logger.error { "Error in validate_encoded_time(): #{e.message}" }
    end
    valid
  end


  private


  def set_values
    if self.repository.nil?
      generate
      setup_defaults
    end
  end


  def generate
    if self.key.nil?
      write_attribute(:key, (0...64+rand(64) ).map{65.+(rand(25)).chr}.join)
    end
  end


  def setup_defaults
    write_attribute(:git_http,   RedmineGitolite::ConfigRedmine.get_setting(:gitolite_http_by_default))
    write_attribute(:git_daemon, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_daemon_by_default, true) ? 1 : 0)
    write_attribute(:git_notify, RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_by_default, true) ? 1 : 0)
    write_attribute(:default_branch, 'master')
  end

end
