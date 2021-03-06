module Kernel
  module_function

  # Instructs Web Console to render a console in the specified binding.
  #
  # If +binding+ isn't explicitly given it will default to the binding of the
  # previous frame. E.g. the one that invoked +console+.
  #
  # Raises DoubleRenderError if a double +console+ invocation per request is
  # detected.
  def console(binding = WebConsole.caller_bindings.first)
    raise WebConsole::DoubleRenderError if Thread.current[:__web_console_binding]

    Thread.current[:__web_console_binding] = binding

    # Make sure nothing is rendered from the view helper. Otherwise
    # you're gonna see unexpected #<Binding:0x007fee4302b078> in the
    # templates.
    nil
  end
end

module ActionDispatch
  class DebugExceptions
    def render_exception_with_web_console(env, exception)
      render_exception_without_web_console(env, exception).tap do
        error = ExceptionWrapper.new(env, exception).exception

        # Get the original exception if ExceptionWrapper decides to follow it.
        Thread.current[:__web_console_exception] = error

        # ActionView::Template::Error bypass ExceptionWrapper original
        # exception following. The backtrace in the view is generated from
        # reaching out to original_exception in the view.
        if error.is_a?(ActionView::Template::Error)
          Thread.current[:__web_console_exception] = error.original_exception
        end
      end
    end

    alias_method :render_exception_without_web_console, :render_exception
    alias_method :render_exception, :render_exception_with_web_console
  end
end
