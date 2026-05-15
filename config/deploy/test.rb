# frozen_string_literal: true

# server 'fixity-test-1.svc.cul.columbia.edu', user: fetch(:remote_user), roles: %w[app db web]
server 'not-currently-available.svc.cul.columbia.edu', user: fetch(:remote_user), roles: %w[app db web]
# In test/prod, suggest latest tag as default version to deploy
ask :branch, proc { `git tag --sort=version:refname`.split("\n").last }
