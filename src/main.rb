#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require_relative "bundle/bundler/setup"
require "alfred"
require "json"

basic_user     = ENV['JENKINS_USER_NAME']
basic_password = ENV['JENKINS_PASSWORD']
url            = ENV['JENKINS_URL']
url            = url.chomp("/")
cache          = "/tmp/jenkins-repositories.json"

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback

  if File.exists?(cache) and File.stat(cache).mtime > Time.now - 60*60*2
    j = File.read(cache)
  else
    j = `curl --silent --user #{basic_user}:#{basic_password} #{url}/api/json`
    File.write(cache, j)
  end
  added = []
  api = JSON.load(j)
  api['jobs'].concat(api['views']).sort_by{|o| o['name']}.each do |o|
    name = o['name']
    next if added.include? name
    added << name
    url = o['url']
    color = o.has_key?('color') ? o['color'] : 'icon'
    fb.add_item({
      :uid      => "",
      :title    => "#{name}",
      :icon     => {
        :type => "filetype",
        :name => "#{color}.png"
      },
      :subtitle => "#{url}",
      :arg      => url,
      :valid    => "yes",
    })
  end

  puts fb.to_xml(ARGV)
end