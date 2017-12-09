require "../model_spec"

module Model::ValidationSpec
  class User < Core::Model
    schema :users do
      primary_key :id
      field :name, String, validate: {
        size:   (1..16),
        regex:  /\w+/,
        custom: ->(name : String) {
          error!(:name, "has reserved value") if %w(foo bar baz).includes?(name)
        },
      }
      field :age, Int32, nilable: true, validate: {min!: 17}
      field :height, Float64?, validate: {in: (0.5..2.5)}
      field :iq, Int32?, validate: {min: 100, max!: 200}
    end

    validate do
      error!(:age, "cannot be greater than 150 (yet)") if age.try &.> 150
    end
  end

  describe "inline validation" do
    describe "#name" do
      user = User.new(name: "Alex")

      it "passes validation" do
        user.valid?.should be_true
      end

      it "validates presence" do
        user.name = nil
        user.validate
        user.errors.should eq ([{:name => "must not be nil"}])
      end

      it "validates size" do
        user.name = ""
        user.validate
        user.errors.should eq ([{:name => "must have size in range of 1..16"}])
      end

      it "validates regex" do
        user.name = "%%%"
        user.validate
        user.errors.should eq ([{:name => "must match /w+/"}])
      end

      it "validates custom" do
        user.name = "foo"
        user.validate
        user.errors.should eq ([{:name => "has reserved value"}])
      end
    end

    describe "#age" do
      user = User.new(name: "Alex", age: 20)

      it "passes validation" do
        user.valid?.should be_true
      end

      it "validates min!" do
        user.age = 17
        user.validate
        user.errors.should eq ([{:age => "must be greater than 17"}])
      end
    end

    describe "#height" do
      user = User.new(name: "Alex", height: 1.0)

      it "passes validation" do
        user.valid?.should be_true
      end

      it "validates in" do
        user.height = 0.1
        user.validate
        user.errors.should eq ([{:height => "must be included in 0.5..2.5"}])
      end
    end

    describe "#iq" do
      user = User.new(name: "Vlad", iq: 135)

      it "passes validation" do
        user.valid?.should be_true
      end

      it "validates min" do
        user.iq = 10
        user.validate
        user.errors.should eq ([{:iq => "must be greater or equal to 100"}])
      end

      it "validates max!" do
        user.iq = 200
        user.validate
        user.errors.should eq ([{:iq => "must be less than 200"}])
      end
    end
  end

  describe "block validation" do
    user = User.new(age: 200)

    it do
      user.validate
      user.errors.includes?({:age => "cannot be greater than 150 (yet)"}).should be_true
    end
  end
end
