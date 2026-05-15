# frozen_string_literal: true

# server 'fixity-dev-1.svc.cul.columbia.edu', user: fetch(:remote_user), roles: %w[app db web]
server 'not-currently-available.svc.cul.columbia.edu', user: fetch(:remote_user), roles: %w[app db web]
# Current branch is suggested by default in development
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
