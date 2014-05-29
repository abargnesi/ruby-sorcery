#!/usr/bin/env ruby
# --------------------------------------------------------------------------
# 
# Name:        method_trace
# Description: Prints before and after traces for all method invocations.
# Tags:        metaprogramming, callbacks, monkey-patch
#
# Usage:       ruby -r "method_trace.rb" program.rb
#
# Explanation: The MethodTrace module intercepts added methods and instance
#              methods of other included modules.  It defines a proxy method
#              that does the following:
#                - calls MethodTrace.before and prints the original method's
#                  source location
#                - call the original method
#                - calls MethodTrace.after with the return value from the
#                  original method
#
#              The Object class is monkey-patched to include MethodTrace
#              to allow all classes of type Object to have method tracing.
#
# --------------------------------------------------------------------------
module MethodTrace

  def before(method)
    (file, lnum) = method.source_location
    puts "* #{method.owner}##{method.original_name} (#{file}:#{lnum})"
  end

  def after(method, retval)
    puts "\u21B3 #{retval.class}: #{retval.inspect}"
  end

  def MethodTrace.included(obj)
    class << obj

      def intercept_method(method_name)
        return if @__last && @__last.include?(method_name)
        proxy = :"#{method_name}_proxy"
        original = :"#{method_name}_original"
        @__last = [method_name, proxy, original]
        define_method proxy do |*args, &block|
          before(self.class.instance_method original)
          retval = send(original, *args, &block)
          after(self.class.instance_method(original), retval)
          return retval
        end
        alias_method original, method_name
        alias_method method_name, proxy
        @__last = nil
      end
      
      def include(*args)
        super(*args)
        args.each do |mod|
          mod.instance_methods.each do |m| intercept_method(m) end
        end
      end

      define_method(:method_added) do |method_name|
        intercept_method method_name
      end
    end
  end
end

class Object
  include MethodTrace
end

# intercept example
if __FILE__ == $0
  # intercept method definitions in class
  class A
    def foo
      "Hit A#foo"
    end
  end
  A.new.foo
  # * A#foo (test.rb:3)
  # ↳ String: "Hit A#foo"

  # intercept included module methods
  module Test
    def foo
      "Hit Test#foo"
    end
  end

  class B
    include Test
  end

  B.new.foo
  # * Test#foo (test.rb:11)
  # ↳ String: "Hit Test#foo"
end

# vim: ts=2 sts=2 sw=2
# encoding: utf-8
