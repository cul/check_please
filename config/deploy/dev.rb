# frozen_string_literal: true

server 'ec2-3-230-115-99.compute-1.amazonaws.com', user: fetch(:remote_user), roles: %w[app db web]
# Current branch is suggested by default in development
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
