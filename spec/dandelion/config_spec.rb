require 'spec_helper'

describe Dandelion::Config do
  let(:data) {{ 'foo' => 'bar' }}

  before(:each) do
    YAML.should_receive(:load_file).with('foo').and_return(data)
  end

  let(:config) { Dandelion::Config.new(path: 'foo') }

  it 'parses yaml config file' do
    expect(config[:foo]).to eq 'bar'
  end
end