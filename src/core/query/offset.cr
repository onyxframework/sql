module Core
  struct Query(T)
    @offset : Int32 | Nil = nil
    protected property offset

    # Add `OFFSET` clause. Unset with `nil`.
    def offset(@offset : Int32 | Nil)
      self
    end

    private macro append_offset(query)
      if @offset
        {{query}} += " OFFSET ?"
        ensure_params.push(@offset.as(DB::Any))
      end
    end
  end
end
