# --------------------------------------------------------------------------
# 
# Name:        MethodTrace
# Description: Prints before and after traces for all method invocations.
# Tags:        metaprogramming, callbacks, monkey-patch
# 
# --------------------------------------------------------------------------
module MethodTrace

  def before(obj, method_name)
    m = obj.class.instance_method :"#{method_name}"
    (file, lnum) = m.source_location
    puts "* #{m.inspect} (#{file}:#{lnum})"
  end

  def after(obj, method_name, retval)
    puts "\u21B3 #{retval.class}: #{retval.inspect}"
  end

  def MethodTrace.included(obj)
    class << obj
      define_method(:method_added) do |method_name|
        return if @__last && @__last.include?(method_name)
        proxy = :"#{method_name}_proxy"
        original = :"#{method_name}_original"
        @__last = [method_name, proxy, original]
        define_method proxy do |*args, &block|
          before(self, method_name)
          retval = send(original, *args, &block)
          after(self, method_name, retval)
          return retval
        end
        alias_method original, method_name
        alias_method method_name, proxy
        @__last = nil
      end
    end
  end
end

class Object
  include MethodTrace
end

class Example

  def foo
    "foo"
  end

  def bar
    {is_a_bar: true}
  end

  def baz
    [:baz, :baz.to_s.size]
  end
end

ex = Example.new
ex.foo
# * #<UnboundMethod: Example#foo(foo_proxy)> (method_intercept.rb:20)
# ↳ String: "foo"

ex.bar
# * #<UnboundMethod: Example#bar(bar_proxy)> (method_intercept.rb:20)
# ↳ Hash: {:is_a_bar=>true}

ex.baz
# * #<UnboundMethod: Example#baz(baz_proxy)> (method_intercept.rb:20)
# ↳ Array: [:baz, 3]

# vim: ts=2 sts=2 sw=2
# encoding: utf-8
