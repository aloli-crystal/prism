require "./spec_helper"

describe Prism::Preferences do
  it "initializes with defaults" do
    prefs = Prism::Preferences.new
    prefs.editor_width_pct.should eq(50.0)
    prefs.dark_mode.should be_false
    prefs.window_width.should eq(1280)
    prefs.window_height.should eq(820)
    prefs.preview_visible.should be_true
    prefs.sidebar_visible.should be_false
  end

  it "serializes to JSON" do
    prefs = Prism::Preferences.new
    json = JSON.parse(prefs.to_json)
    json["editor_width_pct"].as_f.should eq(50.0)
    json["dark_mode"].as_bool.should be_false
  end

  it "allows setting properties" do
    prefs = Prism::Preferences.new
    prefs.dark_mode = true
    prefs.editor_width_pct = 60.0
    prefs.dark_mode.should be_true
    prefs.editor_width_pct.should eq(60.0)
  end
end
