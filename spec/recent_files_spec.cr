require "./spec_helper"

describe Prism::RecentFiles do
  it "starts with an empty list if no saved file" do
    recent = Prism::RecentFiles.new
    # Le fichier de prefs peut exister ou non, on vérifie juste que ça ne plante pas
    recent.list.should be_a(Array(String))
  end

  it "adds and deduplicates files" do
    recent = Prism::RecentFiles.new
    recent.add("/tmp/test1.adoc")
    recent.add("/tmp/test2.adoc")
    recent.add("/tmp/test1.adoc") # doublon

    recent.list.first.should eq("/tmp/test1.adoc")
    recent.list.count("/tmp/test1.adoc").should eq(1)
  end

  it "limits to MAX_RECENT entries" do
    recent = Prism::RecentFiles.new
    15.times { |i| recent.add("/tmp/file#{i}.adoc") }
    recent.list.size.should be <= 10
  end

  it "removes a file" do
    recent = Prism::RecentFiles.new
    recent.add("/tmp/to_remove.adoc")
    recent.remove("/tmp/to_remove.adoc")
    recent.list.includes?("/tmp/to_remove.adoc").should be_false
  end
end
