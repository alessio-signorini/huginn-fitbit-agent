require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FitbitAgent do
  before(:each) do
    @valid_options = Agents::FitbitAgent.new.default_options
    @checker = Agents::FitbitAgent.new(:name => "FitbitAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
