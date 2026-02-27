require "rails_helper"

class RepositoryHygieneSpec
  def self.files_to_scan
    Dir.glob("{app,config,spec}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }
  end
end

RSpec.describe RepositoryHygieneSpec do
  it "has no merge conflict markers in tracked source files" do
    offenders = described_class.files_to_scan.select do |path|
      File.read(path).match?(/^(<<<<<<<|=======|>>>>>>>)/)
    end

    expect(offenders).to be_empty, "Found merge conflict markers in: #{offenders.join(', ')}"
  end
end
