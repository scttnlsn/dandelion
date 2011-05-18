require 'dandelion/backend/sftp'
require 'mocha'
require 'net/sftp'
require 'test/unit'

class TestSFTP < Test::Unit::TestCase
  def setup
    @sftp = mock()
    Net::SFTP.stubs(:start).returns(@sftp)
    @backend = Dandelion::Backend::SFTP.new('path' => 'foo')
    class << @backend
      def temp(file, data)
        yield(:temp)
      end
    end
  end
  
  def test_read
    file = mock()
    @sftp.stubs(:file).returns(file)
    file.expects(:open).with('foo/bar', 'r').once
    file.expects(:open).with('foo/bar/baz', 'r').once
    file.expects(:open).with('foo/bar/baz/qux', 'r').once
    @backend.read('bar')
    @backend.read('bar/baz')
    @backend.read('bar/baz/qux')
  end
  
  def test_write
    @sftp.expects(:upload!).with(:temp, 'foo/bar').once
    @sftp.expects(:upload!).with(:temp, 'foo/bar/baz').once
    @backend.write('bar', 'baz')
    @backend.write('bar/baz', 'qux')
  end
  
  def test_delete
    @sftp.expects(:remove!).with('foo/bar').once
    @sftp.expects(:remove!).with('foo/bar/baz').once
    @sftp.expects(:remove!).with('foo/bar/baz/qux').once
    @sftp.expects(:rmdir!).with('foo/bar').twice
    @sftp.expects(:rmdir!).with('foo/bar/baz').once
    @backend.stubs(:empty?).returns(true)
    @backend.delete('bar')
    @backend.delete('bar/baz')
    @backend.delete('bar/baz/qux')
  end
end