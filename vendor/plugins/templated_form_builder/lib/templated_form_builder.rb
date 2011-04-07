class TemplatedFormBuilder < ActionView::Helpers::FormBuilder
  (field_helpers + %w[date_select datetime_select collection_select select time_zone_select] - %w[label check_box fields_for]).each do |helper|
    define_method(helper) do |*args|
      options = args.extract_options!
      method  = args.first.to_sym
      label_text = extract_label(method, options)
      args << options
      render_form_element helper, method, label_text, options, super(*args)
    end
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    render_form_element :check_box, method.to_sym, extract_label(method, options), options, super(method, options, checked_value, unchecked_value)
  end

  def section(label='Section', options = {}, &block)
    partial = options.delete(:partial) || "section"
    locals = {
      :section_label => label,
      :section_contents => block_given? ? @template.capture(&block) : nil
    }
    @template.concat(@template.render(:partial => "forms/#{partial}", :locals => locals), block.binding)
  end

  def submit(text, options = { })
    button text, options.merge(:type => 'submit')
  end

  def reset(text, options = { })
    button text, options.merge(:type => 'reset')
  end

  def button(content, options = { })
    @template.content_tag 'button', content, options
  end

  private
    def render_form_element(helper, method, label_text, options, element)
      locals = {
        :label => label_text.blank? ? '' : label(method, label_text),
        :element => element
      }

      locals[:errors] = @object.nil? ? [] : Array(@object.errors.on(method))

      begin
        @template.render :partial => "forms/#{helper}", :locals => locals
      rescue ActionView::ActionViewError
        @template.render :partial => 'forms/element', :locals => locals
      end
    end

    def extract_label(method, options)
      options.delete(:label) do
        method.to_s.humanize
      end
    end
end
