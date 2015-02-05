require 'spec_helper'

describe Dandelion::Config do
  let(:yaml) do
    <<-YAML
      foo: bar
      baz: <%= ENV['BAZ'] %>
    YAML
  end

  before(:each) do
    ENV['BAZ'] = 'qux'
    expect(IO).to receive(:read).with('foo').and_return(yaml)
  end

  let(:config) { Dandelion::Config.new(path: 'foo') }

  it 'parses YAML' do
    expect(config[:foo]).to eq 'bar'
  end

  it 'parses ERB' do
    expect(config[:baz]).to eq 'qux'
  end
end
