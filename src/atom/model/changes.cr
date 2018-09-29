module Atom::Model
  # Define `changes` getter for this schema. It will track all changes made to instance's attributes, be it a scalar attribute or a reference.
  private macro define_changes
    {% types = MODEL_ATTRIBUTES.map(&.["type"]) + MODEL_REFERENCES.select(&.["direct"]).map(&.["type"]) %}
    {% types = types + [DB::Default.class] if (MODEL_ATTRIBUTES + MODEL_REFERENCES.select(&.["direct"])).find(&.["db_default"]) %}

    # A storage for changes, empty on initialization. To reset use `changes.clear`.
    getter changes = Hash(String, {{types.join(" | ").id}}).new

    {% for type in MODEL_ATTRIBUTES + MODEL_REFERENCES.select(&.["direct"]) %}
      # :nodoc:
      def {{type["name"]}}=(value : {{type["type"]}}{{" | DB::Default.class".id if type["db_default"]}})
        changes[{{type["name"].stringify}}] = value unless @{{type["name"]}} == value
        @{{type["name"]}} = value
      end
    {% end %}
  end
end
