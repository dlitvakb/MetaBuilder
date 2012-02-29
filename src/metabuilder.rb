class Object
  def singleton_class
    class << self; self; end
  end
end

module MetaBuilder
  def model klass
    @_model ||= klass
  end

  def _validate_type value, expected_type
    if not value.is_a? expected_type
      raise TypeError.new("Should be a #{expected_type}")
    end
  end

  def _validate_ranged value, expected_values
    if not expected_values.include? value
      raise OptionError.new("Should be one of #{expected_values.join(", ")}")
    end
  end

  def _validate_proc value, closure
    if not closure.call value
      raise ValidationError.new("The value did not pass the validations")
    end
  end

  def property name, options=Hash.new
    singleton_class.class_eval do
      if options[:required]
        if instance_variable_defined? "@_required_variables"
          instance_variable_get("@_required_variables") << name
        end
      end

      define_method "validate_#{name}" do |value|
        _validate_type value, options[:type] if options.key? :type
        _validate_ranged value, options[:one_of] if options.key? :one_of
        _validate_proc value, options[:validates] if options.key? :validates
      end

      define_method name do
        instance_variable_get("@#{name}")
      end

      define_method "#{name}=" do |value|
        if options[:required]
          raise RequiredFieldError.new("This field is required") if value.nil?
        end
        send "validate_#{name}".to_sym, value
        instance_variable_set("@#{name}", value)
      end
    end
  end

  def _get_properties_names
    matches = methods.select { |e| /\w+=/.match e.to_s }
    properties = []
    matches.each { |e|
      properties << e.to_s.gsub("=", "")
    }
    properties
  end

  def _building_properties
    properties = _get_properties_names
    building_properties = {}
    properties.each { |e|
      if instance_variable_defined? "@#{e}"
        building_properties[e] = instance_variable_get("@#{e}")
      end
    }
    building_properties
  end

  def build
    result_model = @_model.new
    _building_properties.each_pair { |name, value|
      result_model.instance_eval do
        instance_variable_set("@#{name}", value)
        singleton_class.send :define_method, name.to_sym do
          instance_variable_get("@#{name}")
        end
      end
    }
    result_model
  end
end

class OptionError < StandardError; end
class ValidationError < StandardError; end
class RequiredFieldError < StandardError; end
