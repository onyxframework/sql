module Atom
  struct Query(T)
    @group_by : Array(String) | Nil = nil
    protected property group_by

    # Add `GROUP_BY` clause.
    def group_by(*values : String)
      @group_by = Array(String).new if @group_by.nil?
      @group_by.not_nil!.concat(values)
      self
    end

    private macro append_group_by(query)
      unless @group_by.nil?
        {{query}} += " GROUP BY #{@group_by.not_nil!.join(", ")}"
      end
    end
  end
end
