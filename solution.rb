signature = ENV['COUNT_CALLS_TO']

instance_method = signature.match(/#(.+$)/)[1] if signature.match(/#(.+$)/)
class_method = signature.match(/\.(.+$)/)[1] if signature.match(/\.(.+$)/)
constant = signature.match(/(.+)(\.|#).+$/)[1]

$count = []

eval "class #{constant}; end"

constant = eval constant

if instance_method
  constant.class_eval { define_method(instance_method.to_s.to_sym) {} } unless constant.instance_methods.include? instance_method.to_s.to_sym
  override = <<RB
    alias_method :old, :#{instance_method}
    def #{instance_method}(*args)
      $count << 1
      old(*args)
    end
RB
else
  constant.class_eval do
    singleton_class = class << self; self; end
    singleton_class.class_eval { define_method(class_method.to_s.to_sym) {} }
  end unless constant.singleton_methods.include? class_method.to_s.to_sym
  override = <<RB
    class << self
      alias_method :old, :#{class_method}
      def #{class_method}(*args)
        $count << 1
        old(*args)
      end
    end
RB
end

constant.class_eval override

at_exit do
  puts "#{signature} called #{$count.size} times"
end
