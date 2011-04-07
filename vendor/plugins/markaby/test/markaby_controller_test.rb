require File.expand_path(File.join('test', 'test_helper'))

# The Markaby Rails tests themselves.
class MarkabyControllerTest < Test::Unit::TestCase
  include ActionController::TestProcess
  include ActionController::TestCase::Assertions
  include ActionController::Assertions::ResponseAssertions

  def setup
    @controller = MarkabyController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @expected_monkey_names = '<ul><li>Frank</li><li>Benny</li><li>Paul</li></ul>'
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'markaby/index'
    assert_equal @expected_monkey_names, @response.body
  end
  
  def test_partial_rendering
    Markaby::Builder.set :indent, 2
    process :partial_rendering
    expected_html = File.read(File.join(File.dirname(__FILE__), 'monkeys.html'))
    assert_response :success
    assert_template 'markaby/_monkeys'
    assert_equal expected_html, @response.body
    
    # From actionpack/lib/action_view/base.rb:
    #   String keys are deprecated and will be removed shortly.
    #
    assert_raise ActionView::TemplateError do
      process :partial_rendering_with_stringy_keys_in_local_assigns
    end
  end

  def test_inline_helper_rendering
    process :inline_helper_rendering
    assert_response :success
    assert_equal @expected_monkey_names, @response.body
  end  

  def test_basic_inline_rendering
    process :basic_inline_rendering
    assert_response :success
    assert_equal @expected_monkey_names, @response.body
  end  

  def test_flash_and_form_tag
    process :create
    assert_response :success
    assert_select 'form div input[type=submit]', 1
    assert_select 'p', 'Hello World'
  end

  def test_multiple_form_tags
    process :multiple_forms
    assert_response :success
    assert_select 'form[id=monkeys]', 1
    assert_select 'form[id=bananas]', 1
  end
  
  def test_template_error_has_correct_line_number
    begin
      process :broken
    rescue ActionView::TemplateError => error
      assert_equal 5, error.line_number.to_i
    end
  end

end
