require 'rubygems'
require 'micronaut'
require 'ruby-debug'

SAFE_ROOT = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(SAFE_ROOT, 'lib'))

require 'astrails/safe'

def not_in_editor?
  !(ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM'))
end

Micronaut.configure do |c|
  c.color_enabled = not_in_editor?
  c.filter_run :focused => true
  c.mock_with :rr
end