# frozen_string_literal: true

server 'fixity-test-1.svc.cul.columbia.edu', user: fetch(:remote_user), roles: %w[app db web]
# Current branch is suggested by default in development
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
