require 'test/unit'
require_relative '../src/metabuilder'

class Person
end

class PersonBuilder
  include MetaBuilder

  def initialize
    model Person

    property :name
    property :age, :type => Integer
    property :job, :one_of => ["doctor", "musician"]
    property :height, :validates => Proc.new { |value|
      first_part = value.split("\"").first.to_i
      second_part = value.split("\"").last.gsub("'","").to_i

      first_part_ok = first_part >= 0
      second_part_ok = (0..12).member? second_part

      first_part_ok and second_part_ok
    }

    required :name
  end
end

class MetaBuilderTest < Test::Unit::TestCase
  def setup
    @builder = PersonBuilder.new
  end

  def test_should_have_meta_builder_as_a_module
    assert PersonBuilder.included_modules.include?(MetaBuilder),
           "should have MetaBuilder"
  end

  def test_should_be_able_to_add_a_model
    assert_equal Person, @builder.instance_variable_get("@_model")
  end

  def test_should_be_able_te_create_a_single_property_setter
    assert_respond_to @builder, :name=
    assert_respond_to @builder, :age=
    assert_respond_to @builder, :job=
  end

  def test_should_be_able_te_create_a_single_property_getter
    assert_respond_to @builder, :name
    assert_respond_to @builder, :age
    assert_respond_to @builder, :job
  end

  def test_should_be_able_to_set_constraints_to_a_setter
    @builder.name = "pepe"
    @builder.age = 21
    assert_equal 21, @builder.age

    assert_raise TypeError do
      @builder.age = "fail"
    end
  end

  def test_should_be_able_to_set_ranged_values
    @builder.job = "doctor"
    assert_equal "doctor", @builder.job

    assert_raise OptionError do
      @builder.job = "verdulero"
    end
  end

  def test_should_be_able_to_do_custom_validations
    @builder.height = "6\"1'"
    assert_equal "6\"1'", @builder.height

    assert_raise ValidationError do
      @builder.height = "6\"13'"
    end
  end

  def test_should_not_build_if_required_property_is_nil
    assert_equal nil, @builder.name

    assert_raise RequiredFieldError do
      @builder.build
    end
  end

  def test_should_be_able_to_set_required_fields
    @builder.name = "pepe"
    assert_equal "pepe", @builder.name

    assert_raise RequiredFieldError do
      @builder.name = nil
    end
  end

  def test_should_respond_to_build
    assert_respond_to @builder, :build
  end

  def test_build_should_return_a_model_instance
    @builder.name = "pepe"
    assert @builder.build.is_a?(Person), "should be a Person"
  end

  def test_should_be_able_to_build_a_model_with_all_the_correct_values
    @builder.name = "pepe"
    @builder.age = 21
    @builder.job = "musician"

    person = @builder.build

    assert_respond_to person, :name
    assert_respond_to person, :age
    assert_respond_to person, :job

    assert_equal "pepe", person.name
    assert_equal 21, person.age
    assert_equal "musician", person.job
  end

  def test_should_be_able_to_build_more_than_one_model
    @builder.name = "pepe"
    @builder.age = 21
    @builder.job = "musician"

    person1 = @builder.build

    @builder.name = "juan"
    @builder.age = 25

    person2 = @builder.build

    assert_equal "pepe", person1.name
    assert_equal 21, person1.age
    assert_equal "musician", person1.job

    assert_equal "juan", person2.name
    assert_equal 25, person2.age
    assert_equal "musician", person2.job
  end
end
