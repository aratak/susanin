require 'test_helper'

class SusaninResourceTest < Minitest::Test

  def setup
    @a_klass = Class.new { def inspect; "a_klass##{self.object_id}"; end; def self.inspect; "a_klass"; end; }
    @b_klass = Class.new { def inspect; "b_klass##{self.object_id}"; end; def self.inspect; "b_klass"; end; }
    @c_klass = Class.new { def inspect; "c_klass##{self.object_id}"; end; def self.inspect; "c_klass"; end; }

    @a = @a_klass.new
    @b = @b_klass.new
    @c = @c_klass.new

    @resources = {
      :a_prefix => ->(r) { :qwe },
      :another_prefix => ->(r) { :wer },
      @a_klass => ->(r) { :ert },
      [@a_klass] => ->(r) { :newer_happen }, # because array with single element is unwrapped to element
      [@a_klass, @b_klass] => ->(r) { :tyu },
      [@a_klass, :middle_prefix, @c_klass] => ->(r) { :yui }
    }
    @resources.default = ->(r) {r}

    @resources2 = {
      :a_prefix => ->(r) { [:global_prefix, r] },
      :another_prefix => ->(r) { [:global_prefix, r] },
      @a_klass => ->(r) { [:a_prefix, r] },
      [@a_klass] => ->(r) { [:a_prefix, r] },
      [@a_klass, @b_klass] => ->(r) { [:another_prefix, *r] },
      [@a_klass, :middle_prefix, @c_klass] => ->(r) { "result" }
    }
    @resources2.default = ->(r) {r}
  end

  def test_pattern_params_return_pattern_instance
    assert ::Susanin::Resource.new.pattern_params([]).is_a?(::Susanin::Pattern), '#pattern_params should be instance of ::Susanin::Pattern'
  end

  def test_assertion_1
    subject = ::Susanin::Resource.new({
      :a_prefix => ->(r) { [:global_prefix, r] },
      :another_prefix => ->(r) { [:global_prefix, r] },
      @a_klass => ->(r) { [:a_prefix, r] },
      [@a_klass] => ->(r) { [:a_prefix, r] },
      [@a_klass, @b_klass] => ->(r) { [:another_prefix, *r] },
      [@a_klass, :middle_prefix, @c_klass] => ->(r) { "result" }
    })

    # assert subject.url_parameters([@a]) == [:global_prefix, :a_prefix, @a]
    # assert subject.url_parameters([@a, @b]) == [:global_prefix, :another_prefix, @a, @b]
    # assert subject.url_parameters([@a, :middle_prefix, @c]) == "result"
  end

  def test_get_key
    subject = ::Susanin::Resource.new
    assert subject.get_key(1) == Fixnum
    assert subject.get_key(:'1') == :'1'
    assert subject.get_key([1, :'1']) == [Fixnum, :'1']
    assert subject.get_key([String, 1, :'1', :qwe]) == [String, Fixnum, :'1', :qwe]
    assert subject.get_key(nil) == NilClass
    assert subject.get_key('1') == '1'
    assert subject.get_key(String) == String
    assert subject.get_key(true) == TrueClass
  end

  def test_merged_options
    subject = ::Susanin::Resource.new
    assert subject.merged_options([1, {}], {}), [1]
    assert subject.merged_options([1, {a: 1}], {}), [1, {a: 1}]
    assert subject.merged_options([1, {a: 1}], {b: 2}), [1, {a: 1, b: 2}]
    assert subject.merged_options([1, {a: 1}], {a: 2}), [1, {a: 1}]
  end

  def test_get_result
    subject = ::Susanin::Resource.new()

    assert subject.get_result(:a_prefix, 1, @resources) == :qwe
    assert subject.get_result(@a_klass, 1, @resources) == :ert
    assert subject.get_result([@a_klass], 1, @resources) == :ert
    assert subject.get_result([@a_klass, @b_klass], 1, @resources) == :tyu
    assert subject.get_result([@a_klass, @c_klass], 1, @resources) == :tyu
    assert subject.get_result([@a_klass, :middle_prefix, @c_klass], 1, @resources) == :yui
    assert subject.get_result(:non_exist, 1, @resources) == 1
    assert subject.get_result([:non_exist, :second], 1, @resources) == 1
  end

  def test_resources_except
    subject = ::Susanin::Resource.new()

    assert subject.resources_except(@resources, :a_prefix).keys.to_set == [:another_prefix, @a_klass, [@a_klass], [@a_klass, @b_klass], [@a_klass, :middle_prefix, @c_klass]].to_set
    assert subject.resources_except(@resources, [@a_klass, @b_klass]).keys.to_set == [:a_prefix, :another_prefix, [@a_klass, :middle_prefix, @c_klass]].to_set
    assert subject.resources_except(@resources, [@a_klass, :middle_prefix, @c_klass]).keys.to_set == [:a_prefix, :another_prefix, [@a_klass, @b_klass]].to_set
    assert subject.resources_except(@resources, [@a_klass]).keys.to_set == [:a_prefix, :another_prefix, [@a_klass, @b_klass], [@a_klass, :middle_prefix, @c_klass]].to_set
  end

  def test_get
    subject = ::Susanin::Resource.new()

    # assert subject.get(@a, @resources2).flatten == [:global_prefix, :a_prefix, @a]
    # assert subject.get([@a, @b], @resources2).flatten == [:global_prefix, :another_prefix, @a, @b]
    # assert subject.get([:a_prefix, :another_prefix, @c], @resources2).flatten == [:global_prefix, :a_prefix, :global_prefix, :another_prefix, @c]
    # assert subject.get([:a_prefix, @a], @resources2).flatten == [:global_prefix, :a_prefix, :global_prefix, :a_prefix, @a]
  end

end
