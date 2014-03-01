require 'spec_helper'

describe Dandelion::Adapter::Base do
  describe '#create_adapter' do
    it 'registers adapter classes' do
      class TestAdapter < Dandelion::Adapter::Base
        adapter :test
      end

      expect(Dandelion::Adapter::Base.create_adapter(:test)).to be_a(TestAdapter)
    end

    it 'raises error on invalid adapter' do
      expect {
        Dandelion::Adapter::Base.create_adapter(:another)
      }.to raise_error(Dandelion::Adapter::InvalidAdapterError)
    end

    it 'registers gem list' do
      class TestAdapter < Dandelion::Adapter::Base
        adapter :test
        requires_gems :foo, :bar
      end

      expect(TestAdapter.required_gems).to eq [:foo, :bar]
    end

    it 'catches load errors' do
      class TestAdapter < Dandelion::Adapter::Base
        adapter :test

        def initialize(options)
          raise LoadError
        end
      end

      expect {
        Dandelion::Adapter::Base.create_adapter(:test)
      }.to raise_error(Dandelion::Adapter::MissingDependencyError)
    end
  end
end