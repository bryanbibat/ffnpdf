require_relative '../lib/ffnpdf'

require "test_notifier/runner/rspec"

TestNotifier.default_notifier = :notify_send
