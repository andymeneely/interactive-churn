require 'spec_helper'
require 'set'

describe "JsonOutput class" do

  before(:each) do
    @directory_name = Dir.getwd + "/spec/samplerepo"
    ChurnStandard.root_directory = @directory_name
  end

  it "returns churns metrics in json format" do
    ChurnStandard.root_directory = @directory_name
    expect(JsonOutput.standard ChurnStandard.compute).to eq( "{\"Commits\":10,\"Total Churn\":68,\"Lines added\":48,\"Lines deleted\":20}")
  end

  it "returns churns metrics in json format" do
    expect(JsonOutput.affected_lines ChurnAffectedLine.compute).to eq( "{\"Affected lines\":12}")
  end
end