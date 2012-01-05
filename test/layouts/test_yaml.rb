
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts

  class TestYaml < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.yaml({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
      Thread.current[:name] = nil
    end

    def test_format
      h = {
        'level' => 'INFO',
        'logger' => 'ArrayLogger',
        'message' => 'log message'
      }

      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      assert_yaml_match h, @layout.format(event)

      event.data = [1, 2, 3, 4]
      h['message'] = "<Array> #{[1,2,3,4]}"
      assert_yaml_match h, @layout.format(event)

      event.level = @levels['debug']
      event.data = 'and another message'
      h['level'] = 'DEBUG'
      h['message'] = 'and another message'
      assert_yaml_match h, @layout.format(event)

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      h['level'] = 'FATAL'
      h['logger'] = 'Test'
      h['message'] = '<Exception> Exception'
      assert_yaml_match h, @layout.format(event)
    end

    def test_items
      assert_equal %w[timestamp level logger message], @layout.items
    end

    def test_items_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.items = %w[timestamp]
      assert_equal %w[timestamp], @layout.items
      assert_match %r/\A--- ?\ntimestamp: '?#@date_fmt'?\n/, @layout.format(event)

      # 'foo' is not a recognized item
      assert_raise(ArgumentError) {
        @layout.items = %w[timestamp logger foo]
      }
    end

    def test_items_all
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      event.file = 'test_file.rb'
      event.line = 123
      event.method = 'method_name'

      @layout.items = %w[logger]
      assert_match %r/\A--- ?\nlogger: TestLogger\n/, @layout.format(event)

      @layout.items = %w[file]
      assert_match %r/\A--- ?\nfile: test_file.rb\n/, @layout.format(event)

      @layout.items = %w[level]
      assert_match %r/\A--- ?\nlevel: INFO\n/, @layout.format(event)

      @layout.items = %w[line]
      assert_match %r/\A--- ?\nline: 123\n/, @layout.format(event)

      @layout.items = %w[message]
      assert_match %r/\A--- ?\nmessage: log message\n/, @layout.format(event)

      @layout.items = %w[method]
      assert_match %r/\A--- ?\nmethod: method_name\n/, @layout.format(event)

      @layout.items = %w[pid]
      assert_match %r/\A--- ?\npid: \d+\n\z/, @layout.format(event)

      @layout.items = %w[millis]
      assert_match %r/\A--- ?\nmillis: \d+\n\z/, @layout.format(event)

      @layout.items = %w[thread_id]
      assert_match %r/\A--- ?\nthread_id: -?\d+\n\z/, @layout.format(event)

      @layout.items = %w[thread]
      assert_match %r/\A--- ?\nthread: \n/, @layout.format(event)
      Thread.current[:name] = "Main"
      assert_match %r/\A--- ?\nthread: Main\n/, @layout.format(event)
    end

    private

    def assert_yaml_match( expected, actual )
      actual = YAML.load(actual)

      assert_match %r/#@date_fmt/o, actual['timestamp']
      assert_equal expected['level'], actual['level']
      assert_equal expected['logger'], actual['logger']
      assert_equal expected['message'], actual['message']
    end

  end  # class TestYaml
end  # module TestLayouts
end  # module TestLogging

# EOF
