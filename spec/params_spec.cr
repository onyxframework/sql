require "./spec_helper"
require "../src/core/params"

module ParamsSpec
  describe "Core.prepare_params" do
    context "with single argument" do
      it do
        Core.prepare_params(42).should eq ({42})
      end
    end

    context "with multiple arguments" do
      it do
        Core.prepare_params(42, "foo").should eq ({42, "foo"})
      end
    end

    context "with single enumerable argument" do
      it do
        Core.prepare_params([42, 43]).should eq ({42, 43})
      end
    end

    # TODO: Flatten?
    context "with multiple enumerable arguments" do
      it do
        Core.prepare_params([42, 43], "foo").should eq ({[42, 43], "foo"})
      end
    end
  end
end
