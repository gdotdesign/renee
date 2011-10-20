$: << File.expand_path('../../../renee_core/lib', __FILE__)
$: << File.expand_path('../../lib', __FILE__)
require 'renee_core'
require 'renee_render'

# TODO better registration method (?)
ReneeCore::Application.send(:include, ReneeRender)

# Load shared test helpers
require File.expand_path('../../../lib/test_helper', __FILE__)
