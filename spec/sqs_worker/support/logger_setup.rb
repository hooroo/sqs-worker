module LoggerSetup
  extend RSpec::SharedContext

  let(:logger) { double('logger', info: nil, debug: nil, error: nil) }
end