require 'huginn_agent'

class Engine < ::Rails::Engine; end

#HuginnAgent.load 'huginn_fitbit_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_fitbit_agent/fitbit_agent'
