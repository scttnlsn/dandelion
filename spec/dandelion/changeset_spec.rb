require 'spec_helper'

describe Dandelion::Changeset do
  context 'empty local path' do
    let(:changeset) { test_changeset }

    describe '#enumerable' do
      let(:changes) { changeset.to_a }

      it 'returns all changes' do
        expect(changes).to be_a(Array)
        expect(changes.length).to eq 5
        expect(changes.map(&:path)).to eq ['bar', 'baz/foo', 'baz/bar', 'foo', 'qux']
        expect(changes.map(&:type)).to eq [:delete, :delete, :write, :write, :write]
      end

      it 'returns data for write changes' do
        expect(changes.select { |c| c.type == :write }.map(&:data)).to eq ["bar\n", "foo\n", ""]
      end
    end

    describe '#empty?' do
      it 'returns false' do
        expect(changeset.empty?).to eq false
      end
    end
  end

  context 'non-empty local path' do
    let(:changeset) { test_changeset(local_path: './baz') }

    describe '#enumerable' do
      let(:changes) { changeset.to_a }

      it 'returns all changes' do
        expect(changes).to be_a(Array)
        expect(changes.length).to eq 2
        expect(changes.map(&:path)).to eq ['foo', 'bar']
        expect(changes.map(&:type)).to eq [:delete, :write]
      end

      it 'returns data for write changes' do
        expect(changes.last.data).to eq "bar\n"
      end
    end

    describe '#empty?' do
      it 'returns false' do
        expect(changeset.empty?).to eq false
      end
    end
  end

  context 'empty diff' do
    let(:changeset) { test_changeset }
    before(:each) { allow(changeset).to receive(:diff) { [] } }

    describe '#enumerable' do
      let(:changes) { changeset.to_a }

      it 'returns no changes' do
        expect(changes).to be_a(Array)
        expect(changes.length).to eq 0
      end
    end

    describe '#empty?' do
      it 'returns true' do
        expect(changeset.empty?).to eq true
      end
    end
  end

  context 'diff adds symlink' do
    let(:changeset) { test_changeset_with_symlinks }

    describe '#enumerable' do
      let(:changes) { changeset.to_a }

      it 'returns all changes' do
        expect(changes).to be_a(Array)
        expect(changes.length).to eq 1
        expect(changes.map(&:path)).to eq ['link']
        expect(changes.map(&:type)).to eq [:symlink]
      end

      it 'returns data for write changes' do
        expect(changes.select { |c| c.type != :delete }.map(&:data)).to eq ["baz/bar"]
      end
    end

    describe '#empty?' do
      it 'returns false' do
        expect(changeset.empty?).to eq false
      end
    end
  end

end
