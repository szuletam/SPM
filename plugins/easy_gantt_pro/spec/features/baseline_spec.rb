require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Baseline', :logged => :admin, :js => true do
  let!(:project_no_baseline) { FactoryGirl.create(:project, add_modules: %w(easy_gantt)) }
  let!(:project) { FactoryGirl.create(:project, add_modules: %w(easy_gantt easy_baselines)) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      example.run
    end
  end

  it 'should not be displayed if module is turned of' do
    visit easy_gantt_path(project_no_baseline)
    wait_for_ajax
    # expect(page).to have_selector('#button_critical')
    # expect(page).to have_selector('#button_back')
    expect(page).to have_no_selector('#button_baseline')
  end

  it 'should load empty header' do
    # TODO: Remove this conditions
    skip if EasyGantt.platform == 'easyproject'

    visit easy_gantt_path(project)
    wait_for_ajax
    expect(page).to have_selector('#button_baseline')
    find('#button_baseline').click
    expect(page).to have_selector('#baseline_create')
    expect(page).to have_no_selector('#baseline_select')
  end

  it 'create, load and delete new baseline' do
    # TODO: Remove this conditions
    skip if EasyGantt.platform == 'easyproject'

    visit easy_gantt_path(project)
    wait_for_ajax
    find('#button_baseline').click
    expect(page).to have_no_selector('.gantt-baseline')
    find('#baseline_create').click
    within('#form-modal') do
      fill_in(I18n.t(:field_name), :with => 'Baseline of '+project.name)
    end
    find('#baseline_modal_submit').click
    wait_for_ajax 20
    expect(page).to have_selector('#baseline_select') #.to have_content('Baseline of '+project.name)
    expect(page).to have_selector('.gantt-baselines')
    expect(page).to have_selector('.gantt-baseline')
    message = accept_confirm do
      find('#baseline_delete').click
    end
    expect(message).to eq(I18n.t(:text_are_you_sure))
    expect(page).to have_no_selector('.gantt-baseline')
    expect(page).to have_no_selector('#baseline_select')
  end

end
