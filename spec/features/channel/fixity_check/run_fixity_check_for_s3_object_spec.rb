# frozen_string_literal: true

# rubocop:disable RSpec/ExampleLength

# NOTE: When troubleshooting websocket feature tests, make sure to tail
# logs/test.log while testing so that you can see errors that are raised on a separate thread.

require 'rails_helper'

# Runs the given block in a new thread, but stops the thread
# after the given max_run_time (in seconds) has elapsed.
# @return [Thread] A reference to the thread.
def with_separate_thread(max_run_time, &block)
  Thread.new do
    Timeout.timeout(max_run_time, &block)
  rescue Timeout::Error
    # Capture and ignore Timeout::Error
  end
end

def authorized_websocket_connection
  ws_url = "#{Capybara.current_session.server_url.gsub('http:', 'ws:')}/cable"
  # ws_url = 'ws://localhost:4000/cable'
  Faye::WebSocket::Client.new(ws_url, nil, {
    headers: { 'Authorization' => "Bearer: #{CHECK_PLEASE['remote_request_api_key']}" }
  })
end

# NOTE: For an overview of the Action Cable API, this is a useful article:
# https://stanko.io/deconstructing-action-cable-DC7F33OsjGmK

# NOTE: `js: true` is required for websocket feature tests so that we can
# get the server url from Capybara.current_session.server_url.
RSpec.describe 'run_fixity_check_for_s3_object action', type: :feature, js: true do
  let(:received_messages) { [] }
  let(:job_identifier) { 'job-123' }
  let(:bucket_name) { 'example-bucket' }
  let(:valid_object_path) { 'valid/object/path.png' }
  let(:invalid_object_path) { 'invalid/object/path.png' }
  let(:checksum_algorithm_name) { 'sha256' }
  let(:file_content) { 'A' * 1024 }
  let(:checksum_hexdigest) { Digest::SHA256.hexdigest(file_content) }
  let(:object_size) { file_content.bytesize }

  before do
    allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).with(
      bucket_name,
      valid_object_path,
      checksum_algorithm_name,
      on_chunk: Proc # any Proc
    ).and_return([checksum_hexdigest, object_size])

    allow(CheckPlease::Aws::ObjectFixityChecker).to receive(:check).with(
      bucket_name,
      invalid_object_path,
      checksum_algorithm_name,
      on_chunk: Proc # any Proc
    ).and_raise(StandardError, 'This is an error')

    # NOTE: We run EM inside a thread with a timeout just in case EventMachine::stop_event_loop
    # is never called because of an error.
    t = with_separate_thread(10) do
      EM.run do
        ws = authorized_websocket_connection

        ws.on :open do |event|
          # p [:open]
        end

        ws.on :message do |event|
          data = JSON.parse(event.data)
          # p [:message, data]
          received_messages << data unless data['type'] == 'ping' # We're ignoring ping messages

          if data['type'] == 'welcome'
            # After welcome message is received, subscribe to the FixityCheckChannel
            ws.send(
              {
                'command': 'subscribe',
                'identifier': { 'channel': 'FixityCheckChannel', 'job_identifier': job_identifier }.to_json
              }.to_json
            )
          elsif data['type'] == 'confirm_subscription'
            # After receiving a subscription confirmation, send a run_fixity_check_for_s3_object message on the channel
            ws.send(
              {
                'command': 'message',
                'identifier': { 'channel': 'FixityCheckChannel', 'job_identifier': job_identifier }.to_json,
                'data': {
                  'action': 'run_fixity_check_for_s3_object',
                  'bucket_name': bucket_name,
                  'object_path': object_path,
                  'checksum_algorithm_name': checksum_algorithm_name
                }.to_json
              }.to_json
            )
          elsif data['type'].nil? && data['message'].present?
            if JSON.parse(data['identifier']) == {
              'channel' => 'FixityCheckChannel', 'job_identifier' => job_identifier
            }
              ws.close
            end
          end
        end

        ws.on :close do |_event|
          # p [:close, event.code, event.reason]
          ws = nil
          EventMachine.stop_event_loop
        end
      end
    end
    t.join
  end

  context 'when a client subscribes to a FixityCheckChannel stream based on job_identifier and sends a '\
          'run_fixity_check_for_s3_object message for a valid object' do
    let(:object_path) { valid_object_path }

    it 'completes successfully and broadcasts the expected response' do
      expect(received_messages[0]).to eq({ 'type' => 'welcome' })
      expect(received_messages[1]).to eq({
        'type' => 'confirm_subscription',
        'identifier' => { 'channel' => 'FixityCheckChannel', 'job_identifier' => job_identifier }.to_json
      })
      expect(received_messages[2]).to eq(
        {
          'identifier' => { 'channel' => 'FixityCheckChannel', 'job_identifier' => job_identifier }.to_json,
          'message' => {
            'type' => 'fixity_check_complete',
            'data' => {
              'bucket_name' => bucket_name,
              'object_path' => object_path,
              'checksum_algorithm_name' => checksum_algorithm_name,
              'checksum_hexdigest' => checksum_hexdigest,
              'object_size' => object_size
            }
          }.to_json
        }
      )
    end
  end

  context 'when a client subscribes to a FixityCheckChannel stream based on job_identifier and sends a '\
          'run_fixity_check_for_s3_object message for an invalid object' do
    let(:object_path) { invalid_object_path }

    it 'fails to calculate a checksum and broadcasts the expected error response' do
      expect(received_messages[0]).to eq({ 'type' => 'welcome' })
      expect(received_messages[1]).to eq({
        'type' => 'confirm_subscription',
        'identifier' => { 'channel' => 'FixityCheckChannel', 'job_identifier' => job_identifier }.to_json
      })
      expect(received_messages[2]).to eq(
        {
          'identifier' => { 'channel' => 'FixityCheckChannel', 'job_identifier' => job_identifier }.to_json,
          'message' => {
            'type' => 'fixity_check_error',
            'data' => {
              'error_message' => 'This is an error',
              'bucket_name' => bucket_name,
              'object_path' => object_path,
              'checksum_algorithm_name' => checksum_algorithm_name
            }
          }.to_json
        }
      )
    end
  end
end
