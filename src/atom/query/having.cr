module Atom
  struct Query(T)
    struct Having
      getter clause, params, or, not

      def initialize(
        @clause : String,
        @params : Array(DB::Any | Array(DB::Any)) | Nil = nil,
        @or : Bool = false,
        @not : Bool = false
      )
      end
    end

    @having : Array(Having) | Nil = nil
    protected property having

    # Add `HAVING` *clause* with *params*.
    #
    # ```
    # query.having("COUNT(tags.id) > ?", 5) # HAVING (COUNT(tags.id) > ?)
    # ```
    #
    # Multiple calls concatenate clauses with `AND`:
    #
    # ```
    # query.having("COUNT(tags.id) > ?", 5).having("foo = ?", "bar")
    # # HAVING (COUNT(tags.id) > ?) AND (foo = ?)
    # ```
    #
    # See also `#and`, `#or`, `#and_having`, `#and_having_not`, `#or_having`, `#or_having_not`.
    def having(clause : String, *params : DB::Any | Array(DB::Any), or : Bool = false, not : Bool = false)
      ensure_having << Having.new(
        clause: clause,
        params: params.to_a.map do |param|
          if param.is_a?(Array)
            param.map(&.as(DB::Any))
          else
            param.as(DB::Any | Array(DB::Any))
          end
        end,
        or: or,
        not: not
      )

      @latest_wherish_clause = :having

      self
    end

    # Add `HAVING` *clause* without params.
    #
    # ```
    # query.having("COUNT(tags.id) > 5") # HAVING (COUNT(tags.id) > 5)
    # ```
    #
    # Multiple calls concatenate clauses with `AND`:
    #
    # ```
    # query.having("COUNT(tags.id) > 5").having("foo = 'bar'")
    # # HAVING (COUNT(tags.id) > 5) AND (foo = 'bar')
    # ```
    #
    # See also `#and`, `#or`, `#and_having`, `#and_having_not`, `#or_having`, `#or_having_not`.
    def having(clause : String, or : Bool = false, not : Bool = false)
      ensure_having << Having.new(
        clause: clause,
        params: nil,
        or: or,
        not: not
      )

      @latest_wherish_clause = :having

      self
    end

    # Add `NOT` *clause* with *params* to `HAVING`.
    #
    # ```
    # having_not("count = ?", 42)
    # # HAVING (...) AND NOT (count = ?)
    # ```
    def having_not(clause, *params)
      having(clause, *params, not: true)
    end

    # Add `NOT` *clause* to `HAVING`.
    #
    # ```
    # having_not("count = 42")
    # # HAVING (...) AND NOT (count = 42)
    # ```
    def having_not(clause)
      having(clause, not: true)
    end

    {% for or in [true, false] %}
      {% for not in [true, false] %}
        # Add `{{or ? "OR".id : "AND".id}}{{" NOT".id if not}}` *clause* with *params* to `HAVING`.
        #
        # ```
        # {{(or ? "or" : "and").id}}_having{{"_not".id if not}}("count = ?", 42)
        # # HAVING (...) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(count = ?)
        # ```
        def {{(or ? "or" : "and").id}}_having{{"_not".id if not}}(clause : String, *params)
          having(clause, *params, or: {{or}}, not: {{not}})
        end

        # Add `{{or ? "OR".id : "AND".id}}{{" NOT".id if not}}` *clause* to `HAVING`.
        #
        # ```
        # {{(or ? "or" : "and").id}}_having{{"_not".id if not}}("count = 42")
        # # HAVING (...) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(count = 42)
        # ```
        def {{(or ? "or" : "and").id}}_having{{"_not".id if not}}(clause : String)
          having(clause, or: {{or}}, not: {{not}})
        end
      {% end %}
    {% end %}

    protected def ensure_having
      @having = Array(Having).new if @having.nil?
      @having.not_nil!
    end

    private macro append_having(query)
      unless @having.nil?
        {{query}} += " HAVING "
        first_clause = true

        {{query}} += @having.not_nil!.join(" ") do |clause|
          c = ""
          c += (clause.or ? "OR " : "AND ") unless first_clause
          c += "NOT " if clause.not
          c += "(#{clause.clause})"

          first_clause = false

          unless clause.params.nil?
            ensure_params.concat(clause.params.not_nil!)
          end

          c
        end
      end
    end
  end
end
