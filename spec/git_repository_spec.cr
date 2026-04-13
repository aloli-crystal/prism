require "./spec_helper"

describe Prism::Git::Repository do
  it "detects the current git repository" do
    # Ce test tourne dans le repo prism lui-même
    repo = Prism::Git::Repository.new(Dir.current)
    repo.valid?.should be_true
    repo.root.should_not be_empty
  end

  it "returns current branch" do
    repo = Prism::Git::Repository.new(Dir.current)
    if repo.valid?
      repo.current_branch.should_not be_empty
    end
  end

  it "returns status summary as JSON" do
    repo = Prism::Git::Repository.new(Dir.current)
    if repo.valid?
      json = JSON.parse(repo.status_summary)
      json["branch"].as_s.should_not be_empty
    end
  end

  it "handles invalid path gracefully" do
    repo = Prism::Git::Repository.new("/tmp/nonexistent_repo_#{rand(99999)}")
    repo.valid?.should be_false
    repo.file_tree.should eq("[]")
    repo.current_branch.should eq("")
  end
end
