# frozen_string_literal: true

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode.
      DiscourseEvent.trigger(:web_fork_started)
      Discourse.after_fork

      # Reconnecting to the database is handled by passenger.
    else
      # We're in direct spawning mode. We don't need to do anything.
    end
  end
end

# This file is used by Rack-based servers to start the application.
ENV["DISCOURSE_RUNNING_IN_RACK"] = "1"

require ::File.expand_path('../config/environment',  __FILE__)

map ActionController::Base.config.try(:relative_url_root) || "/" do
  run Discourse::Application
end
