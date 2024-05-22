# frozen_string_literal: true

worker_processes ENV.fetch("UNICORN_WORKERS", Etc.nprocessors).to_i

working_directory ENV["STACK_PATH"]

listen ENV["CUSTOM_WEB_SOCKET_FILE"], backlog: 64

timeout 30

pid ENV["CUSTOM_WEB_PID_FILE"]

stderr_path "#{ENV["STACK_PATH"]}/log/unicorn.stderr.log"
stdout_path "#{ENV["STACK_PATH"]}/log/unicorn.stdout.log"

preload_app true

check_client_connection false

# XXX
# # local variable to guard against running a hook multiple times
# run_once = true

before_fork do |server, _worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  ActiveRecord::Base.connection.disconnect!

  Discourse.redis.close

  # XXX
  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  # old_pid = "#{server.config[:pid]}.oldbin"
  # if old_pid != server.pid
  #   begin
  #     sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
  #     Process.kill(sig, File.read(old_pid).to_i)
  #   rescue Errno::ENOENT, Errno::ESRCH
  #   end
  # end

  old_pid = "#{ENV["CUSTOM_WEB_PID_FILE"]}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

  # XXX
  # if run_once
  #   # do_something_once_here ...
  #   run_once = false # prevent from firing again
  # end

  # XXX
  # DiscoursePluginRegistry.demon_processes.each do |demon_class|
  #   server.logger.info "starting #{demon_class.prefix} demon"
  #   demon_class.start
  # end

  # XXX
  #     class ::Unicorn::HttpServer
  #       alias master_sleep_orig master_sleep
  #
  #       def master_sleep(sec)
  #         DiscoursePluginRegistry.demon_processes.each { |demon_class| demon_class.ensure_running }
  #
  #         master_sleep_orig(sec)
  #       end
  #     end

  # XXX
  # Throttle the master from forking too quickly by sleeping.  Due
  # to the implementation of standard Unix signal handlers, this
  # helps (but does not completely) prevent identical, repeated signals
  # from being lost when the receiving process is busy.
  # sleep 1
end

# See `Discourse.after_fork`: All forking servers must call this after fork, otherwise Discourse will be in a bad state.
after_fork do |_server, _worker|
  # the following is *required* for Rails + "preload_app true",
  ActiveRecord::Base.establish_connection

  DiscourseEvent.trigger(:web_fork_started)
  Discourse.after_fork
end
