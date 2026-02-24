require "rails_helper"

class RepositoryHygieneSpec; end

RSpec.describe RepositoryHygieneSpec do
  it "has no merge conflict markers in tracked source files" do
    files = Dir.glob("{app,config,spec}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }

    offenders = files.select do |path|
      content = File.read(path)
      content.match?(/^(<<<<<<<|=======|>>>>>>>)/)
    end

    expect(offenders).to be_empty, "Found merge conflict markers in: #{offenders.join(', ')}"
  end
end
