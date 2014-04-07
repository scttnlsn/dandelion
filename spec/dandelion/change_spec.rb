require 'spec_helper'

describe Dandelion::Change do
  let(:read) { -> { 'baz' }}
  let(:change) { Dandelion::Change.new('foo', 'bar', read) }

  it 'has path' do
    expect(change.path).to eq 'foo'
  end

  it 'has type' do
    expect(change.type).to eq 'bar'
  end

  it 'has data' do
    expect(change.data).to eq 'baz'
  end
end