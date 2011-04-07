class MarkabyController < ApplicationController
  helper :test

  @@locals = { :monkeys => Monkey.find(:all) }

  def rescue_action(e) raise e end;

  def index
    @monkeys = Monkey.find(:all)
  end

  def create
    flash[:message] = 'Hello World'
  end

  def broken
  end

  def multiple_forms
  end

  def partial_rendering
    render :partial => 'monkeys', :locals => @@locals
  end

  def partial_rendering_with_stringy_keys_in_local_assigns
    render :partial => 'monkeys', :locals => { 'monkeys' => Monkey.find(:all) }
  end

  def inline_helper_rendering
    render_markaby(:locals => @@locals) { ul { monkeys.each { |m| li m.name } } }
  end

  def basic_inline_rendering
    render :inline => mab { ul { Monkey.find(:all).each { |m| li m.name } } }
  end
end