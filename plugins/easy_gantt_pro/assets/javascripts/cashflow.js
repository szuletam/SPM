window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.cashflow = ysy.pro.cashflow || {};
$.extend(ysy.pro.cashflow, {
  name: "CashFlow",
  styles: {
    positive: {textColor: "#484848", fontStyle: "12px Courier"},
    negative: {textColor: "#ff0000", fontStyle: "12px Courier"}
  },
  doNotCloseToolPanel: true,
  registeredOnLoader: false,
  buttonExtendee: {
    id: "cashflow",
    bind: function () {
      this.model = ysy.settings.cashflow;
      this._register(ysy.settings.resource);
    },
    func: function () {
      if (!this.isOn()) {
        ysy.pro.cashflow.open();
      } else {
        ysy.pro.cashflow.close();
      }
    },
    isOn: function () {
      return ysy.settings.cashflow.active;
    },
    isHidden: function () {
      return ysy.settings.resource.open;
    }
  },
  patch: function () {
    // do not load feature if there is no Cashflow button
    if (!$("#easy_gantt_menu").find("#button_cashflow").length) return;
    ysy.settings.cashflow = new ysy.data.Data();
    ysy.settings.cashflow.init({
      _name: "CashFlow",
      active: false
    });
    ysy.proManager.register("close", this.close);
    if (ysy.settings.global) {
      ysy.view.AllButtons.prototype.extendees.cashflow = this.buttonExtendee;
    } else {
      ysy.pro.toolPanel.registerButton(this.buttonExtendee);
    }

    ysy.pro.sumRow.summers.cashflow = {
      day: function (date, project) {
        // if(!project.isProject) return 0;
        if (!project._cashflow) return 0;
        // if (project.start_date.isAfter(date)) return 0;
        // if (project.end_date.isBefore(date)) return 0;
        if (project._shift) {
          date = moment(date).subtract(project._shift, "days");
        }
        return project._cashflow[date.format("YYYY-MM-DD")] || 0;
      },
      week: function (first_date, last_date, project) {
        // if(!project.isProject) return 0;
        if (!project._cashflow) return 0;
        // if (project.start_date.isAfter(last_date)) return 0;
        // if (project.end_date.isBefore(first_date)) return 0;
        var sum = 0;
        var mover = moment(first_date);
        if (project._shift) {
          mover.subtract(project._shift, "days");
          last_date = moment(last_date).subtract(project._shift, "days");
        }
        while (mover.isBefore(last_date)) {
          var cash = project._cashflow[mover.format("YYYY-MM-DD")];
          if (cash) sum += cash;
          mover.add(1, "day");
        }
        return sum;
      },
      formatter: ysy.pro.cashflow.formatter,
      entities: ["projects"],
      title: "CashFlow"
    };
    // var projectRenderer = gantt.config.type_renderers["project"] || gantt._task_default_render;
    // gantt.config.type_renderers["project"] = function (task) {
    //   var div = projectRenderer.call(this, task);
    //   if (ysy.settings.cashflow.active) {
    //     var allodiv = ysy.pro.cashflow.project_canvas_renderer(task);
    //     if (allodiv) div.appendChild(allodiv);
    //   }
    //   return div;
    // };
  },
  open: function () {
    var setting = ysy.settings.cashflow;
    if (setting.setSilent("active", true)) {
      var cashflowClass = ysy.pro.cashflow;
      cashflowClass.loadCashflow();
      ysy.view.bars.registerRenderer("project", this.outerRenderer);
      ysy.settings.sumRow.setSummer("cashflow");
      cashflowClass.eventId = gantt.attachEvent("onTaskClick", cashflowClass.showTooltip);
      ysy.proManager.closeAll(this);
      if (!this.registeredOnLoader) {
        this.registeredOnLoader = true;
        ysy.data.loader.register(function () {
          if (!setting.active) return;
          this.loadCashflow()
        }, this);
      }
      setting._fireChanges(this, "toggle");
    }
  },
  close: function () {
    var setting = ysy.settings.cashflow;
    if (setting.setSilent("active", false)) {
      ysy.view.bars.removeRenderer("project", ysy.pro.cashflow.outerRenderer);
      ysy.settings.sumRow.removeSummer("cashflow");
      gantt.detachEvent(ysy.pro.cashflow.eventId);
      setting._fireChanges(this, "toggle");
    }
  },
  showTooltip: function (projectId, e) {
    var $target = $(e.target);
    if (!$target.hasClass("gantt-task-bar-canvas")) return true;
    var project = gantt._pull[projectId];
    if (!project) return true;
    var graphOffset = $target.closest(".gantt_bars_area").offset();
    var zoom = ysy.settings.zoom.zoom;
    var date = moment(gantt.dateFromPos2(e.pageX - graphOffset.left)).startOf(zoom === "week" ? "isoWeek" : zoom);
    var out = ysy.pro.cashflow.tooltipOut(project.widget.model, date, zoom);
    if (out.dates.length === 0) return true;
    ysy.view.tooltip.show("gantt-tooltip-cashflow", e, ysy.view.templates.CashflowTooltip, out);
    return false;
  },
  noHtmlFormatter: function (value, width) {
    return ysy.pro.cashflow.formatter(value, width, true);
  },
  formatter: function (value, width, noHtml) {
    if (value === 0) return 0;
    var negative = value < 0;
    value = Math.abs(value);
    var rounded;
    if (value < 1000) {
      rounded = ysy.pro.cashflow.roundTo2(value);
    } else if (value < 1000000) {
      rounded = ysy.pro.cashflow.roundTo2(value / 1000) + "k";
    } else {
      rounded = ysy.pro.cashflow.roundTo2(value / 1000000) + "M";
    }
    if (width > 35 && negative) {
      rounded = "-" + rounded;
    }
    if (noHtml) {
      return rounded;
    }
    if (negative) {
      return '<span title="' + value + '" class="gantt-sum-row-negative">' + rounded + '</span>';
    }
    return '<span title="' + value + '">' + rounded + '</span>';
  },
  roundTo2: function (value) {
    if (value >= 100) return (Math.floor(value / 10) * 10).toString();
    if (value >= 10) return Math.floor(value).toString();
    return value.toFixed(1);
  },
  loadCashflow: function (projectId) {
    var ids = [];
    var project;
    if (projectId) {
      ids.push(projectId);
    } else {
      var projects = ysy.data.projects.getArray();
      for (var i = 0; i < projects.length; i++) {
        project = projects[i];
        ids.push(project.id);
      }
    }
    // var fakedData = this.prepareFakeData(start_date, end_date, ids);
    // return this._handleCashflowData(fakedData);
    ysy.gateway.polymorficPostJSON(
        ysy.settings.paths.cashflow,
        {
          project_ids: ids
        },
        $.proxy(this._handleCashflowData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    );
  },
  _handleCashflowData: function (data) {
    var json = data.easy_cashflow_data;
    if (!json) return;
    this._resetProjects();
    this._loadProjects(json.projects);
  },
  _resetProjects: function () {
    var projects = ysy.data.projects.getArray();
    for (var i = 0; i < projects.length; i++) {
      delete projects[i]._cashflow;
      delete projects[i]._expected_expenses;
      delete projects[i]._expected_revenues;
    }
  },
  _loadProjects: function (json) {
    var projects = ysy.data.projects;
    for (var i = 0; i < json.length; i++) {
      var project = projects.getByID(json[i].project_id);
      if (!project) continue;
      project._expected_expenses = json[i].expected_expenses;
      project._expected_revenues = json[i].expected_revenues;
      var cashflow_data = {};
      for (var j = 0; j < project._expected_expenses.length; j++) {
        var expense = project._expected_expenses[j];
        if (!cashflow_data[expense.spent_on]) {
          cashflow_data[expense.spent_on] = 0;
        }
        cashflow_data[expense.spent_on] -= expense.price1;
      }
      for (j = 0; j < project._expected_revenues.length; j++) {
        var revenue = project._expected_revenues[j];
        if (!cashflow_data[revenue.spent_on]) {
          cashflow_data[revenue.spent_on] = 0;
        }
        cashflow_data[revenue.spent_on] += revenue.price1;
      }
      var dates = Object.getOwnPropertyNames(cashflow_data).sort();
      if (dates.length > 0) {
        var start_date = moment(dates[0]);
        var end_date = moment(dates[dates.length - 1]);
        var changed = false;
        if (project.start_date.isAfter(start_date)) {
          project.setSilent("start_date", start_date);
          changed = true;
        }
        if (project.end_date.isBefore(end_date)) {
          end_date._isEndDate = true;
          project.setSilent("end_date", end_date);
          changed = true;
        }
        if (changed) {
          project._fireChanges(this, "cashflow data");
        }
      }
      ysy.log.debug("cashflow loaded", "cashflow");


      project._cashflow = cashflow_data;
      project._fireChanges(this, "CashFlow loaded");
    }
  },
  // prepareFakeData: function (start_date, end_date, project_ids) {
  //   var data = [];
  //   for (var i = 0; i < project_ids.length; i++) {
  //     var projectId = project_ids[i];
  //     var project = ysy.data.projects.getByID(projectId);
  //     var projectExpenses = [];
  //     var projectRevenues = [];
  //     var mover = moment(project.start_date);
  //     while (mover.isBefore(project.end_date)) {
  //       if (Math.random() > 0.8) {
  //         // projectCashFlow[mover.format("YYYY-MM-DD")]=Math.floor(Math.random()*200)*100-10000;
  //         var value = Math.exp(-Math.random() * 5) / 2.7 * 1000000;
  //         // var value = Math.random() * 1000000;
  //         if (Math.random() - 0.5 < 0) {
  //           projectExpenses.push({spent_on: mover.format("YYYY-MM-DD"), price1: value});
  //         } else {
  //           projectRevenues.push({spent_on: mover.format("YYYY-MM-DD"), price1: value});
  //         }
  //       }
  //       mover.add(1, "day");
  //     }
  //     data.push({"project_id": projectId, "expected_expenses": projectExpenses, "expected_revenues": projectRevenues});
  //   }
  //   return {"easy_cashflow_data": {"projects": data}};
  // },
  outerRenderer: function (task, next) {
    var div = next().call(this, task, next);
    var cashDiv = ysy.pro.cashflow._projectRenderer.call(gantt, task);
    div.appendChild(cashDiv);
    return div;
  },
  _projectRenderer: function (task) {
    var cashClass = ysy.pro.cashflow;
    var project = task.widget && task.widget.model;
    var canvasList = ysy.view.bars.canvasListBuilder();
    canvasList.build(task, this);
    var cashList = project._cashflow;
    if (ysy.settings.zoom.zoom !== "day") {
      $.proxy(cashClass._projectWeekRenderer, this)(task, cashList, canvasList, project._shift);
    } else {
      $.proxy(cashClass._projectDayRenderer, this)(task, cashList, canvasList, project._shift);
    }
    var element = canvasList.getElement();
    element.className += " project";
    return element;
  },
  _projectDayRenderer: function (task, cashList, canvasList, shift) {
    var cashClass = ysy.pro.cashflow;
    for (var date in cashList) {
      if (!cashList.hasOwnProperty(date)) continue;
      if (!cashList[date]) continue;
      var cash = cashList[date];
      if (shift) {
        var momentDate = moment(date).add(shift, "days");
        if (!canvasList.inRange(momentDate)) continue;
        date = momentDate.format("YYYY-MM-DD");
      } else {
        if (!canvasList.inRange(date)) continue;
      }

      canvasList.fillFormattedTextAt(date, cashClass.noHtmlFormatter, cash, cash < 0 ? cashClass.styles.negative : cashClass.styles.positive);
    }
  },
  _projectWeekRenderer: function (task, cashList, canvasList, shift) {
    var cashClass = ysy.pro.cashflow;
    var weekCash = cashClass.weekCashSummer(cashList, ysy.settings.zoom.zoom, task.start_date, task.end_date, shift);
    for (var date in weekCash) {
      if (!weekCash.hasOwnProperty(date)) continue;
      var cash = weekCash[date];

      canvasList.fillFormattedTextAt(date, cashClass.noHtmlFormatter, cash, cash < 0 ? cashClass.styles.negative : cashClass.styles.positive);
    }
  },
  weekCashSummer: function (cashList, unit, minDate, maxDate, shift) {
    var barsClass = ysy.view.bars;
    var minDateValue = minDate.valueOf();
    var maxDateValue = moment(maxDate).add(1, "days").valueOf();
    var weekCash = {};
    for (var date in cashList) {
      if (!cashList.hasOwnProperty(date)) continue;
      var dateMoment = barsClass.getFromDateCache(date);
      var cash = cashList[date];
      if (shift) {
        dateMoment = moment(dateMoment).add(shift, "days");
        date = dateMoment.format("YYYY-MM-DD");
      }
      if (+dateMoment < minDateValue) continue;
      if (+dateMoment > maxDateValue) continue;
      if (!cash) continue;
      var firstMomentDate = moment(dateMoment).startOf(unit === "week" ? "isoWeek" : unit);
      var firstDate = firstMomentDate.toISOString();
      if (weekCash[firstDate] === undefined) {
        weekCash[firstDate] = cash;
      } else {
        weekCash[firstDate] += cash;
      }
    }
    return weekCash;
  },
  tooltipOut: function (project, date, zoom) {
    var cashData = project._cashflow;
    var allExpenses = project._expected_expenses;
    var allRevenues = project._expected_revenues;
    var dates = [];
    var shift = project._shift;
    if (shift) {
      date.add(shift, "days");
    }
    var endDate = moment(date).add(1, zoom);
    while (date.isBefore(endDate)) {
      var dateString = date.format("YYYY-MM-DD");
      if (!cashData[dateString]) {
        date.add(1, "day");
        continue;
      }
      var expenses = [];
      var revenues = [];
      for (var i = 0; i < allExpenses.length; i++) {
        if (allExpenses[i].spent_on !== dateString) continue;
        expenses.push(allExpenses[i]);
      }
      for (i = 0; i < allRevenues.length; i++) {
        if (allRevenues[i].spent_on !== dateString) continue;
        revenues.push(allRevenues[i]);
      }
      if (expenses.length || revenues.length) {
        dates.push({
              date: date.format("D MMMM YYYY"),
              expenses: expenses,
              revenues: revenues,
              hasExpenses: expenses.length,
              hasRevenues: revenues.length
            }
        );
        if (dates.length === 1) {
          dates[0].first = true;
        }
      }
      date.add(1, "day");
    }
    return {dates: dates};
  }
});
