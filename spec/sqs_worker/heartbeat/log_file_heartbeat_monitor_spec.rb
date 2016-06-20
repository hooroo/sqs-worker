require 'spec_helper'
require 'sqs_worker/heartbeat/log_file_heartbeat_monitor'

module SqsWorker
  module Heartbeat
    describe LogFileHeartbeatMonitor do

      let(:logger) { double('logger', info: nil) }

      let(:threshold_seconds) { 20 }

      subject(:monitor) { described_class.new(logger: logger, threshold_seconds: threshold_seconds) }


      describe "#tick" do
        describe "when no tick has ever occurred" do
          before do
            monitor.tick
          end

          it "should write a heartbeat to the log" do
            expect(logger).to have_received(:info).with('sqs_worker is alive')
          end
        end

        describe "when a subsequent tick has occured AFTER the threshold time" do
          describe "all on the same day" do
            before do
              Timecop.freeze(Time.local(1973, 1, 26, 12, 26, 0)) #matts birthday and time
              monitor.tick

              Timecop.freeze(Time.local(1973, 1, 26, 12, 26, threshold_seconds + 1)) #matts birthday and time
              monitor.tick
            end

            it "should write a second heartbeat to the log" do
              expect(logger).to have_received(:info).twice
            end
          end

          describe "across days" do
            before do
              Timecop.freeze(Time.local(1973, 1, 26, 23, 59, 59)) #matts birthday and time
              monitor.tick

              Timecop.freeze(Time.local(1973, 1, 27, 0, 0, threshold_seconds)) #matts birthday and time
              monitor.tick
            end

            it "should write a second heartbeat to the log" do
              expect(logger).to have_received(:info).twice
            end
          end

          describe "thread safety" do
            let(:fake_mutex) { double(Mutex, synchronize: nil) }

            before do
              allow(Mutex).to receive(:new).and_return(fake_mutex)
            end

            describe "before the mutex yields" do
              before do
                monitor.tick
              end

              it "should wait on the mutex to yield" do
                expect(logger).not_to have_received(:info)
              end
            end

            describe "when the mutex yields" do
              before do
                expect(fake_mutex).to receive(:synchronize).and_yield
                monitor.tick
              end

              it "should wait on the mutex to yield" do
                expect(logger).to have_received(:info).once
              end
            end
          end
        end

        describe "when a subsequent tick has occured BEFORE the threshold time" do
          before do
            Timecop.freeze(Time.local(1973, 1, 26, 12, 26, 0)) #matts birthday and time
            monitor.tick

            Timecop.freeze(Time.local(1973, 1, 26, 12, 26, threshold_seconds - 1)) #matts birthday and time
            monitor.tick
          end

          it "should NOT write a second heartbeat to the log" do
            expect(logger).to have_received(:info).once
          end
        end
      end
    end
  end
end

