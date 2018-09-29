module Atom::Model
  class DefaultValueError < Exception
    def initialize(class klass : String, attribute : String) forall T
      super "#{klass} attribute '#{attribute}' equals to 'DB::Default.class', which is considered unset"
    end
  end
end
