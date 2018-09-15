require "./models"

describe "Query" do
  {% for joinder in %w(and or) %}
    {% for not in [true, false] %}
      describe '#' + {{joinder}} + {{not ? "_not" : ""}} do
        {% for wherish in %w(where having) %}
          context "after " + {{wherish}} do
            it "calls " + {{wherish}} do
              Core::Query(User).new.{{wherish.id}}("foo").{{joinder.id}}{{"_not".id if not}}("bar").should eq Core::Query(User).new.{{wherish.id}}("foo").{{joinder.id}}_{{wherish.id}}{{"_not".id if not}}("bar")
            end
          end
        {% end %}
      end
    {% end %}
  {% end %}
end
