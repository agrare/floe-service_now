# frozen_string_literal: true

RSpec.describe Floe::ServiceNow::Methods do
  it "inherits from Floe::BuiltinRunner::Methods" do
    expect(described_class.superclass).to eq(Floe::BuiltinRunner::Methods)
  end
end
