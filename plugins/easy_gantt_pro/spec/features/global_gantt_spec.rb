require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature  'Global gantt', logged: :admin, js: true do
  let(:subproject) {
    FactoryGirl.create(:project, :parent_id => superproject.id, add_modules: ['easy_gantt'], number_of_issues: 3)
  }
  let(:superproject) {
    FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 3)
  }
  let(:project2) {
    FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 3)
  }
  let(:milestone_issues) {
    FactoryGirl.create_list(:issue, 3, :fixed_version_id => milestone_superproject.id, :project_id => superproject.id)
  }
  let(:milestone_superproject) {
    FactoryGirl.create(:version, project_id: superproject.id)
  }
  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end
  it 'should load projects' do
    superproject
    subproject
    project2
    visit easy_gantt_path
    wait_for_ajax
    expect(page).not_to have_text(subproject.name)
    expect(page).to have_text(superproject.name)
    expect(page).to have_text(project2.name)
  end

  # it 'should open and load subproject' do
  #   project2
  #   visit easy_gantt_path
  #   wait_for_ajax
  #   expect(page).to have_text(project2.name)
  #   project2.issues.each do |issue|
  #     expect(page).not_to have_text(issue.subject)
  #   end
  #   page.find("div[task_id='p#{project2.id}'] .gantt_open").click
  #   wait_for_ajax
  #   expect(project2.issues.length).to eq(3)
  #   project2.issues.each do |issue|
  #     expect(page).to have_text(issue.subject)
  #   end
  # end

end