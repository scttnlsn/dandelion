require 'dandelion/backend/ftp'
require 'net/ftp'
require 'test/unit'
require 'mocha'

class TestFTP < Test::Unit::TestCase
  def setup
    @ftp = mock()
    Net::FTP.stubs(:new).returns(@ftp)
    @ftp.expects(:connect).once
    @ftp.expects(:login).once
    @ftp.expects(:passive=).with(true).once
    @ftp.expects(:chdir).with('foo').once
    @backend = Dandelion::Backend::FTP.new('path' => 'foo')
    class << @backend
      def temp(file, data)
        yield(:temp)
      end
    end
  end
  
  def test_read
    @ftp.expects(:retrbinary).with('RETR bar', 4096).once
    @ftp.expects(:retrbinary).with('RETR bar/baz', 4096).once
    @ftp.expects(:retrbinary).with('RETR bar/baz/qux', 4096).once
    @backend.read('bar')
    @backend.read('bar/baz')
    @backend.read('bar/baz/qux')
  end
  
  def test_write
    @ftp.expects(:putbinaryfile).with(:temp, 'bar').once
    @ftp.expects(:putbinaryfile).with(:temp, 'bar/baz').once
    @backend.write('bar', 'baz')
    @backend.write('bar/baz', 'qux')
  end
  
  def test_delete
    @ftp.expects(:delete).with('bar').once
    @ftp.expects(:delete).with('bar/baz').once
    @ftp.expects(:delete).with('bar/baz/qux').once
    @ftp.expects(:rmdir).with('bar').twice
    @ftp.expects(:rmdir).with('bar/baz').once
    @backend.stubs(:empty?).returns(true)
    @backend.delete('bar')
    @backend.delete('bar/baz')
    @backend.delete('bar/baz/qux')
  end
end
