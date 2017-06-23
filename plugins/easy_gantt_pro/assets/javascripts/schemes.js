window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.schemes = {
  patch: function () {
    ysy.proManager.register("extendGanttTask",this.extendGanttTask);
    ysy.data.schemes = new ysy.data.Array().init({_name:"IssueSchemeArray"});
    ysy.data.projectSchemes = new ysy.data.Array().init({_name:"ProjectSchemeArray"});
    ysy.pro.toolPanel.registerButton({
      id:"scheme_select",
      widget: ysy.view.Select,
      bind: function () {
        this.model = ysy.settings.scheme;
      },
      func: function () {
        var value = this.$target.val();
        this.model.setSilent("by", value);
        this.model._fireChanges(this, value + " selected");
      },
      modelValue: function () {
        return this.model.by;
      }
    });
    ysy.data.loader._loadSchemes = function (json) {
      if (!ysy.settings.easyRedmine) return;
      ysy.data.schemes.clear();
      ysy.data.projectSchemes.clear();
      if (!json) return;
      var schemes = ysy.data.schemes;
      if (json.IssueStatus) schemes.push(new ysy.data.Scheme().init(json.IssueStatus, "issue_status"));
      if (json.IssuePriority) schemes.push(new ysy.data.Scheme().init(json.IssuePriority, "issue_priority"));
      if (json.Tracker) schemes.push(new ysy.data.Scheme().init(json.Tracker, "tracker"));
      if (json.EasyProjectPriority) ysy.data.projectSchemes.push(
          new ysy.data.Scheme().init(json.EasyProjectPriority, "project_priority"));
    }
  },
  extendGanttTask: function (issue, gantt_issue) {
    if (gantt_issue.type === "project") {
      gantt_issue.css += ysy.pro.schemes.getProjectSchemeOf(issue, gantt_issue)
    }
    if (gantt_issue.type === "task" && ysy.data.schemes) {
      gantt_issue.css += ysy.pro.schemes.getSchemeOf(issue, gantt_issue)
    }
  },
  getSchemeOf: function (issue) {
    var scheme = ysy.data.schemes.getByID(ysy.settings.scheme.by);
    if (!scheme) return '';
    return scheme.getSchemeOf(issue);
  },
  getProjectSchemeOf: function (project) {
    if (ysy.settings.scheme.by === "project_status" && project.status_id > 1) {
      return " gantt-scheme-project-status-" + project.status_id;
    }
    var scheme = ysy.data.projectSchemes.getByID(ysy.settings.scheme.by);
    if (!scheme) return '';
    return scheme.getSchemeOf(project);
  }
};
//######################################################################################################################
ysy.data.Scheme = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Scheme, {
  _name: "Scheme",
  issueMapping: {
    issue_priority: "priority_id",
    issue_status: "status_id",
    tracker: "tracker_id",
    project_priority: "priority_id"
  },
  init: function (data, key) {
    this.id = key;
    for (var i = 0; i < data.length; i++) {
      this[data[i].id] = data[i].scheme;
    }
    return this;
  },
  getSchemeOf: function (issue) {
    if (!this.issueMapping[ysy.settings.scheme.by]) return;
    var schemeId = issue[this.issueMapping[ysy.settings.scheme.by]];
    if (this[schemeId]) {
      return " " + this[schemeId];
    }
    return '';
  }
});
