class EasyGanttProController < EasyGanttController
  accept_api_auth :lowest_progress_tasks, :cashflow_data

  # TODO: Calculate progress date on DB
  def lowest_progress_tasks
    project_ids = Array(params[:project_ids])

    @data = Hash.new { |hash, key| hash[key] = { date: Date.new(9999), ids: [] } }

    issues = Issue.open.joins(:status).
                   where(project_id: project_ids).
                   where.not(start_date: nil, due_date: nil).
                   pluck(:project_id, :id, :start_date, :due_date, :done_ratio)

    issues.each do |p_id, i_id, start_date, due_date, done_ratio|
      diff = due_date - start_date
      add_days = (diff * done_ratio.to_i) / 100
      progress_date = start_date + add_days.days

      project_data = @data[p_id]
      if project_data[:date] == progress_date
        project_data[:ids] << i_id
      elsif project_data[:date] > progress_date
        project_data[:date] = progress_date
        project_data[:ids] = [i_id]
      end
    end

    ids = @data.flat_map{|_, data| data[:ids]}
    @issues = Issue.select(:project_id, :id, :subject).where(id: ids)
  end

  def cashflow_data
    unless EasyGantt.easy_money?
      return render_404
    end

    project_ids = Array(params[:project_ids])

    @data = Hash.new { |hash, key| hash[key] = { revenues: [], expenses: [] } }

    revenues = EasyMoneyExpectedRevenue.where(project_id: project_ids).pluck(:project_id, :spent_on, :price1)
    revenues.each do |project_id, spent_on, price1|
      @data[project_id][:revenues] << {spent_on: spent_on, price1: price1}
    end

    expenses = EasyMoneyExpectedExpense.where(project_id: project_ids).pluck(:project_id, :spent_on, :price1)
    expenses.each do |project_id, spent_on, price1|
      @data[project_id][:expenses] << {spent_on: spent_on, price1: price1}
    end
  end

end
